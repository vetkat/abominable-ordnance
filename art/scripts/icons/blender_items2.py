"""Stasis ward and larva rocket icon options, built with the same materials and lighting as the larva icons.
Usage: python blender_items2.py <item> <species> <out.png>
items: ward-canister, ward-pod, ward-hex, rocket-glass, rocket-burst, rocket-bio"""
import math
import bpy
import blender_icons as B
from blender_icons import grime_material, ellipsoid, cone, lumpy, larva, COL, ITEM, OUT


def emission(name, color, strength=6.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*color, 1)
    b.inputs['Emission Color'].default_value = (*color, 1)
    b.inputs['Emission Strength'].default_value = strength
    b.inputs['Roughness'].default_value = 0.2
    return m


def cyl(r, depth, loc, mat, verts=64, rot=(0, 0, 0), bevel=0.04):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object; o.data.materials.append(mat)
    if bevel:
        b = o.modifiers.new('bev', 'BEVEL'); b.width = bevel; b.segments = 3
    bpy.ops.object.shade_smooth()
    return o


def torus(R, r, loc, mat, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot)
    o = bpy.context.active_object; o.data.materials.append(mat); bpy.ops.object.shade_smooth()
    return o


def cut(o, axis=0, keep_above=0.0):
    """Delete the vertices on one side of a local axis (half a sphere -> a dome or a nose)."""
    import bmesh
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co[axis] < keep_above], context='VERTS')
    bm.to_mesh(o.data); bm.free(); o.data.update()


def group(fn, loc=(0, 0, 0), rot=(0, 0, 0), scale=1.0):
    """Run fn, then parent everything it made to an empty, so the whole thing can be turned."""
    before = set(bpy.data.objects)
    fn()
    new = [o for o in bpy.data.objects if o not in before]
    e = bpy.data.objects.new('grp', None); bpy.context.collection.objects.link(e)
    for o in new:
        if o.parent is None:
            o.parent = e
    e.location = loc; e.rotation_euler = rot; e.scale = (scale,) * 3
    return e


def mats():
    return dict(
        metal=grime_material('metal', (0.32, 0.31, 0.29), rough=0.5, metallic=0.85, rust=(0.24, 0.10, 0.04), coat=0.1),
        dark=grime_material('darkmetal', (0.11, 0.105, 0.10), rough=0.55, metallic=0.7, rust=(0.18, 0.08, 0.03), coat=0.1),
        glass=grime_material('glass', (0.82, 0.9, 0.86), rough=0.1, grime=0.6, transmission=0.95, coat=0.6, ior=1.1, bumpk=0.1),
        frost=grime_material('frost', (0.78, 0.86, 0.92), rough=0.75, grime=0.4, sss=0.4, coat=0.0, bumpk=1.5),
        cryo=emission('cryo', (0.25, 0.65, 1.0), 4.0),
        hazard=grime_material('hazard', (0.75, 0.52, 0.06), rough=0.45, grime=1.0, coat=0.2),
        steel=grime_material('steel', (0.45, 0.45, 0.43), rough=0.35, metallic=0.9, coat=0.2),
        grey=grime_material('rocketgrey', (0.30, 0.30, 0.29), rough=0.5, grime=1.2, coat=0.1, rust=(0.16, 0.07, 0.03)),
        olive=grime_material('rocketolive', (0.22, 0.25, 0.12), rough=0.5, grime=1.2, coat=0.1, rust=(0.16, 0.07, 0.03)),
        khaki=grime_material('rocketkhaki', (0.42, 0.37, 0.25), rough=0.5, grime=1.2, coat=0.1, rust=(0.16, 0.07, 0.03)),
        red=grime_material('rocketred', (0.50, 0.08, 0.05), rough=0.5, grime=1.2, coat=0.1, rust=(0.16, 0.07, 0.03)),
    )


# ---------- stasis ward options ----------

def ward_canister(m):
    """Upright cryo canister: metal caps, ribbed frame, frosted glass band over glowing blue coolant."""
    cyl(0.62, 1.3, (0, 0, 1.15), m['cryo'], bevel=0)
    cyl(0.75, 1.2, (0, 0, 1.15), m['glass'], bevel=0)
    for z in (0.35, 1.95):
        cyl(0.86, 0.45, (0, 0, z), m['metal'])
        torus(0.84, 0.06, (0, 0, z + (0.2 if z > 1 else -0.2)), m['dark'])
    for k in range(4):  # frame bars
        a = k / 4 * 2 * math.pi + math.pi / 4
        cyl(0.07, 1.4, (math.cos(a) * 0.8, math.sin(a) * 0.8, 1.15), m['dark'], verts=16, bevel=0.01)
    for z in (0.6, 1.72):  # frost crusted where the glass meets the caps
        f = torus(0.76, 0.06, (0, 0, z), m['frost']); f.scale = (1, 1, 0.8); lumpy(f, 0.04, 2.5)
    cyl(0.18, 0.2, (0, 0, 2.3), m['steel'])


def ward_pod(m):
    """Same canister family as the loaded larva, but empty and frozen: icy coolant under a frosted dome."""
    base = cyl(1.55, 0.4, (0, 0, 0.2), m['metal'], bevel=0.08)
    torus(1.38, 0.12, (0, 0, 0.42), m['dark'])
    for k in range(8):
        a = k / 8 * 2 * math.pi + 0.2
        ellipsoid((math.cos(a) * 1.38, math.sin(a) * 1.38, 0.55), (0.09, 0.09, 0.06), m['metal'], seg=16)
    ellipsoid((0, 0, 0.34), (1.25, 1.25, 0.12), m['cryo'])
    dome = ellipsoid((0, 0, 0.42), (1.3, 1.3, 0.95), m['glass'], seg=64)
    cut(dome, 2, -0.02)
    dome.modifiers.new('thick', 'SOLIDIFY').thickness = 0.05
    f = torus(1.27, 0.08, (0, 0, 0.5), m['frost']); f.scale = (1, 1, 1.4); lumpy(f, 0.05, 2.5)


def ward_hex(m):
    """Hexagonal containment cell: six posts around a glowing stasis field, with emitters on top."""
    cyl(1.5, 0.35, (0, 0, 0.18), m['dark'], verts=6, bevel=0.05)
    ring = torus(1.3, 0.09, (0, 0, 1.75), m['metal'])
    for k in range(6):
        a = k / 6 * 2 * math.pi
        cyl(0.11, 1.5, (math.cos(a) * 1.3, math.sin(a) * 1.3, 0.95), m['metal'], verts=16, bevel=0.02)
        cyl(0.13, 0.12, (math.cos(a) * 1.3, math.sin(a) * 1.3, 1.78), m['cryo'], verts=16, bevel=0.02)
        cyl(0.16, 0.25, (math.cos(a) * 1.3, math.sin(a) * 1.3, 0.45), m['hazard'], verts=16, bevel=0.02)
    field = grime_material('field', (0.55, 0.8, 1.0), rough=0.05, grime=0.2, transmission=0.9, coat=1.0, ior=1.1, bumpk=0.0)
    ellipsoid((0, 0, 1.0), (0.95, 0.95, 0.7), field)
    ellipsoid((0, 0, 1.0), (0.5, 0.5, 0.38), m['cryo'])


# ---------- regular vs cryo ward pairs ----------

def amber(m):
    m.setdefault('amber', emission('amber', (1.0, 0.5, 0.1), 3.0))
    m.setdefault('gel', grime_material('gel', (0.75, 0.42, 0.08), rough=0.08, grime=0.4, sss=0.6, coat=1.0, transmission=0.3))
    m.setdefault('copper', grime_material('copper', (0.55, 0.28, 0.14), rough=0.35, metallic=0.9, rust=(0.15, 0.32, 0.25), coat=0.2))
    m.setdefault('rubber', grime_material('rubber', (0.06, 0.055, 0.05), rough=0.8, grime=0.8, coat=0.0))
    m.setdefault('jarglass', grime_material('jarglass', (0.6, 0.7, 0.66), rough=0.05, grime=0.45, alpha=0.18, coat=1.0, bumpk=0.0))
    return m


def canister(m, cryo):
    """Upright canister. Regular: amber sedative gel, latched shut. Cryo: blue coolant, frost at the seams."""
    amber(m)
    cyl(0.62, 1.3, (0, 0, 1.15), m['cryo'] if cryo else m['amber'], bevel=0)
    cyl(0.75, 1.2, (0, 0, 1.15), m['glass'], bevel=0)
    for z in (0.35, 1.95):
        cyl(0.86, 0.45, (0, 0, z), m['metal'])
        torus(0.84, 0.06, (0, 0, z + (0.2 if z > 1 else -0.2)), m['dark'])
    for k in range(4):
        a = k / 4 * 2 * math.pi + math.pi / 4
        cyl(0.07, 1.4, (math.cos(a) * 0.8, math.sin(a) * 0.8, 1.15), m['dark'], verts=16, bevel=0.01)
    if cryo:
        for z in (0.6, 1.72):
            f = torus(0.76, 0.06, (0, 0, z), m['frost']); f.scale = (1, 1, 0.8); lumpy(f, 0.04, 2.5)
        ellipsoid((0, 0, 2.22), (0.55, 0.55, 0.08), m['frost']); 
        cyl(0.18, 0.2, (0, 0, 2.3), m['steel'])
    else:
        for k in range(3):  # yellow latches clamping the lid
            a = k / 3 * 2 * math.pi + 0.4
            bpy.ops.mesh.primitive_cube_add(size=1, location=(math.cos(a) * 0.88, math.sin(a) * 0.88, 1.8))
            l = bpy.context.active_object; l.scale = (0.1, 0.2, 0.45); l.rotation_euler = (0, 0, a)
            l.data.materials.append(m['hazard']); l.modifiers.new('bev', 'BEVEL').width = 0.03
        cyl(0.22, 0.18, (0, 0, 2.28), m['rubber'])


def jar(m, cryo):
    """Specimen jar. Regular: murky green preservative, rubber stopper, clamp bands.
    Cryo: the same jar frozen solid, frost crust, copper cooling coil wrapped around it."""
    amber(m)
    if cryo:
        liquid = grime_material('ice', (0.55, 0.8, 0.95), rough=0.15, grime=0.6, sss=0.5, coat=0.8, transmission=0.4, bumpk=1.2)
    else:
        liquid = grime_material('preserve', (0.42, 0.55, 0.14), rough=0.05, grime=0.5, sss=0.5, coat=1.0, transmission=0.35)
    cyl(0.72, 1.45, (0, 0, 0.9), liquid, bevel=0.1)
    cyl(0.8, 1.7, (0, 0, 1.0), m['jarglass'], bevel=0.12)
    cyl(0.84, 0.22, (0, 0, 0.12), m['metal'])
    cyl(0.55, 0.35, (0, 0, 1.95), m['rubber'], bevel=0.06)
    for z in (0.55, 1.45):
        torus(0.82, 0.05, (0, 0, z), m['steel'])
    if cryo:
        for k in range(4):  # coil: a few slightly tilted rings, so the ice still shows
            t = torus(0.85, 0.045, (0, 0, 0.62 + k * 0.24), m['copper'], rot=(math.radians(5), 0, k * 0.9))
        for z in (0.3, 1.8):
            f = torus(0.8, 0.09, (0, 0, z), m['frost']); f.scale = (1, 1, 1.3); lumpy(f, 0.05, 2.5)
        f = ellipsoid((0, 0, 2.13), (0.5, 0.5, 0.08), m['frost']); lumpy(f, 0.03, 2.5)
    else:
        for k in range(2):  # wire bail over the stopper
            bpy.ops.mesh.primitive_torus_add(major_radius=0.62, minor_radius=0.025, location=(0, 0, 1.95), rotation=(math.radians(90), 0, k * math.pi / 2))
            w = bpy.context.active_object; w.data.materials.append(m['steel']); w.scale = (1, 1, 0.55)


def hexcell(m, cryo):
    """Hex containment cell. Regular: amber sedation field. Cryo: blue stasis field with frosted base."""
    amber(m)
    glow = m['cryo'] if cryo else m['amber']
    cyl(1.5, 0.35, (0, 0, 0.18), m['dark'], verts=6, bevel=0.05)
    torus(1.3, 0.09, (0, 0, 1.75), m['metal'])
    for k in range(6):
        a = k / 6 * 2 * math.pi
        cyl(0.11, 1.5, (math.cos(a) * 1.3, math.sin(a) * 1.3, 0.95), m['metal'], verts=16, bevel=0.02)
        cyl(0.13, 0.12, (math.cos(a) * 1.3, math.sin(a) * 1.3, 1.78), glow, verts=16, bevel=0.02)
        cyl(0.16, 0.25, (math.cos(a) * 1.3, math.sin(a) * 1.3, 0.45), m['hazard'], verts=16, bevel=0.02)
    fc = (0.55, 0.8, 1.0) if cryo else (1.0, 0.7, 0.35)
    field = grime_material('field', fc, rough=0.05, grime=0.2, transmission=0.9, coat=1.0, ior=1.1, bumpk=0.0)
    ellipsoid((0, 0, 1.0), (0.95, 0.95, 0.7), field)
    ellipsoid((0, 0, 1.0), (0.5, 0.5, 0.38), glow)
    if cryo:
        f = torus(1.25, 0.12, (0, 0, 0.38), m['frost']); f.scale = (1, 1, 0.7); lumpy(f, 0.06, 2.5)


# ---------- larva rocket options ----------

def rocket_body(m, length=2.6, r=0.32, nose=True, color='red'):
    """Vanilla-style rocket along +X: painted body, steel bands, four fins, nozzle; optional ogive nose."""
    rot = (0, math.radians(90), 0)
    cyl(r, length, (0, 0, 0), m[color], rot=rot, bevel=0.03)
    for x in (-length / 2 + 0.25, 0.1, length / 2 - 0.15):
        cyl(r * 1.06, 0.12, (x, 0, 0), m['steel'], rot=rot, bevel=0.02)
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=r * 0.9, radius2=r * 0.45, depth=0.35, location=(-length / 2 - 0.15, 0, 0), rotation=(0, math.radians(90), 0))
    nz = bpy.context.active_object; nz.data.materials.append(m['dark']); bpy.ops.object.shade_smooth()
    for k in range(4):
        a = k / 4 * 2 * math.pi + math.pi / 4
        bpy.ops.mesh.primitive_cube_add(size=1, location=(-length / 2 + 0.3, math.cos(a) * r * 1.6, math.sin(a) * r * 1.6))
        f = bpy.context.active_object; f.scale = (0.55, 0.05, 0.42); f.rotation_euler = (a - math.pi / 2, 0, 0)
        f.data.materials.append(m['metal'])
        bv = f.modifiers.new('bev', 'BEVEL'); bv.width = 0.02; bv.segments = 2
    if nose:
        n = ellipsoid((length / 2, 0, 0), (0.7, r, r), m['steel'])
        cut(n, 0, -0.01)


def rocket_glass(m):
    """A larva curled in a glass nose cone, like a payload window."""
    L = 2.4
    rocket_body(m, length=L, nose=False)
    cyl(0.46, 0.15, (L / 2, 0, 0), m['hazard'], rot=(0, math.radians(90), 0), bevel=0.02)
    g = group(lambda: larva(size=0.28, spikes=False, gross=False), loc=(L / 2 + 0.5, 0.05, -0.16))
    clear = grime_material('noseglass', (0.55, 0.66, 0.62), rough=0.04, grime=0.3, alpha=0.12, coat=1.0, bumpk=0.0)
    nose = ellipsoid((L / 2 + 0.08, 0, 0), (1.0, 0.44, 0.44), clear)
    cut(nose, 0, -0.01)
    nose.modifiers.new('thick', 'SOLIDIFY').thickness = 0.03


def _clear():
    return grime_material('noseglass', (0.55, 0.66, 0.62), rough=0.04, grime=0.3, alpha=0.12, coat=1.0, bumpk=0.0)


def _pointed_nose(m, x0, r, length, mat):
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=r, radius2=0.0, depth=length, location=(x0 + length / 2, 0, 0), rotation=(0, math.radians(90), 0))
    n = bpy.context.active_object; n.data.materials.append(mat); bpy.ops.object.shade_smooth()
    return n


def rocket_window(m):
    """A glass payload section between the body and a pointed steel nose, held by steel struts."""
    L, r, W = 2.0, 0.32, 0.8
    rocket_body(m, length=L, nose=False)
    x0 = L / 2
    for x in (x0, x0 + W):
        cyl(r * 1.12, 0.12, (x, 0, 0), m['hazard'] if x == x0 else m['steel'], rot=(0, math.radians(90), 0), bevel=0.02)
    for k in range(3):
        a = k / 3 * 2 * math.pi + math.pi / 2
        cyl(0.035, W, (x0 + W / 2, math.cos(a) * r * 1.02, math.sin(a) * r * 1.02), m['steel'], verts=12, rot=(0, math.radians(90), 0), bevel=0)
    group(lambda: larva(size=0.27, spikes=False, gross=True), loc=(x0 + W / 2 + 0.05, 0.0, -0.17))
    lt = bpy.data.lights.new('payload', 'POINT'); lt.energy = 6; lt.color = (1.0, 0.75, 0.45); lt.shadow_soft_size = 0.2
    lo = bpy.data.objects.new('payload', lt); bpy.context.collection.objects.link(lo); lo.location = (x0 + W / 2, -0.15, 0.2)
    g = grime_material('winglass', (0.6, 0.7, 0.66), rough=0.03, grime=0.2, alpha=0.07, coat=1.0, bumpk=0.0)
    cyl(r * 0.98, W, (x0 + W / 2, 0, 0), g, rot=(0, math.radians(90), 0), bevel=0)
    _pointed_nose(m, x0 + W + 0.05, r * 1.05, 0.75, m['steel'])


def rocket_cage(m):
    """A pointed steel cage instead of a nose cone, with the larva wedged inside it."""
    L, r = 2.2, 0.32
    rocket_body(m, length=L, nose=False)
    x0 = L / 2
    cyl(r * 1.12, 0.14, (x0, 0, 0), m['hazard'], rot=(0, math.radians(90), 0), bevel=0.02)
    tip = (x0 + 1.05, 0, 0)
    n = 6
    for k in range(n):  # bars from the rim to the tip
        a = k / n * 2 * math.pi
        p0 = (x0, math.cos(a) * r * 1.05, math.sin(a) * r * 1.05)
        mid = [(p0[i] + tip[i]) / 2 for i in range(3)]
        dx, dy, dz = tip[0] - p0[0], tip[1] - p0[1], tip[2] - p0[2]
        ln = math.sqrt(dx * dx + dy * dy + dz * dz)
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.03, depth=ln, location=mid)
        b = bpy.context.active_object; b.data.materials.append(m['steel'])
        b.rotation_mode = 'QUATERNION'
        from mathutils import Vector
        b.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(Vector((dx, dy, dz)))
    for f, rr in ((0.35, 0.7), (0.7, 0.36)):  # hoops
        torus(r * 1.05 * rr, 0.025, (x0 + 1.05 * f, 0, 0), m['steel'], rot=(0, math.radians(90), 0))
    ellipsoid(tip, (0.06, 0.06, 0.06), m['steel'], seg=16)
    group(lambda: larva(size=0.28, spikes=False, gross=True), loc=(x0 + 0.42, 0.0, -0.17))


def rocket_porthole(m):
    """A pointed steel nose with two round portholes; the larva's flesh presses against the glass."""
    L, r = 2.4, 0.32
    rocket_body(m, length=L, nose=False)
    x0 = L / 2
    cyl(r * 1.12, 0.12, (x0, 0, 0), m['hazard'], rot=(0, math.radians(90), 0), bevel=0.02)
    _pointed_nose(m, x0 + 0.04, r * 1.05, 1.0, m['steel'])
    flesh = grime_material('fleshp', COL['flesh'], rough=0.2, sss=0.4, coat=1.0, veins=(3.2, (0.28, 0.03, 0.06)))
    for k, (fx, a) in enumerate(((0.28, math.radians(75)), (0.55, math.radians(20)))):
        rr = r * 1.05 * (1 - fx / 1.0) * 1.0
        cx, cy, cz = x0 + 0.04 + fx, math.cos(a) * rr, math.sin(a) * rr
        nrm = (0, math.cos(a), math.sin(a))
        rot = (math.atan2(-nrm[1], nrm[2]), 0, 0)
        torus(0.1, 0.025, (cx, cy, cz), m['dark'], rot=rot)
        ellipsoid((cx - 0.0, cy * 0.97, cz * 0.97), (0.09, 0.09, 0.09), flesh, seg=24)


def tag(objs, part):
    for o in objs:
        o['part'] = part


def rocket_tintable(m):
    """D1 split into tintable parts: two neutral bands (rear = parent A, front = parent B) and a neutral larva.
    Factorio multiplies each icon layer by its tint, so the bands and larva are rendered pale grey."""
    L, r, W = 2.0, 0.32, 0.8
    import os
    bw = float(os.environ.get('BANDW', '0.12'))
    band = grime_material('band', (0.78, 0.76, 0.72), rough=0.45, grime=0.8, coat=0.2)
    rocket_body(m, length=L, nose=False, color=os.environ.get('BODY', 'red'))
    x0 = L / 2
    # wide bands grow away from the glass, so the window stays the same size
    tag([cyl(r * 1.12, bw, (x0 - (bw - 0.12) / 2, 0, 0), band, rot=(0, math.radians(90), 0), bevel=0.02)], 'band_rear')
    tag([cyl(r * 1.12, bw, (x0 + W + (bw - 0.12) / 2, 0, 0), band, rot=(0, math.radians(90), 0), bevel=0.02)], 'band_front')
    for k in range(3):
        a = k / 3 * 2 * math.pi + math.pi / 2
        cyl(0.035, W, (x0 + W / 2, math.cos(a) * r * 1.02, math.sin(a) * r * 1.02), m['steel'], verts=12, rot=(0, math.radians(90), 0), bevel=0)
    before = set(bpy.data.objects)
    group(lambda: larva(size=0.27, spikes=False, gross=True), loc=(x0 + W / 2 + 0.05, 0.0, -0.17))
    tag([o for o in bpy.data.objects if o not in before and o.type == 'MESH'], 'larva')
    lt = bpy.data.lights.new('payload', 'POINT'); lt.energy = 6; lt.color = (1.0, 0.9, 0.8); lt.shadow_soft_size = 0.2
    lo = bpy.data.objects.new('payload', lt); bpy.context.collection.objects.link(lo); lo.location = (x0 + W / 2, -0.15, 0.2)
    g = grime_material('winglass', (0.6, 0.7, 0.66), rough=0.03, grime=0.2, alpha=0.07, coat=1.0, bumpk=0.0)
    cyl(r * 0.98, W, (x0 + W / 2, 0, 0), g, rot=(0, math.radians(90), 0), bevel=0)
    _pointed_nose(m, x0 + W + 0.05, r * 1.05, 0.75, m['steel'])


def isolate(part):
    """Keep one tagged part visible; everything else becomes a holdout, so it still hides what is behind it."""
    hold = bpy.data.materials.new('holdout'); hold.use_nodes = True
    nt = hold.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); h = nt.nodes.new('ShaderNodeHoldout')
    nt.links.new(h.outputs[0], out.inputs['Surface'])
    for o in bpy.data.objects:
        if o.type != 'MESH' or o.get('part') == part:
            continue
        if any(sl.material and sl.material.name.startswith('winglass') for sl in o.material_slots):
            o.visible_camera = False  # clear glass must not hide the larva behind it
            continue
        for i in range(len(o.material_slots)):
            o.material_slots[i].material = hold


def rocket_burst(m):
    """The nose has split open and the larva's head is pushing out of it."""
    L = 2.4
    rocket_body(m, length=L, nose=False)
    for k in range(4):  # torn nose petals bent outward
        a = k / 4 * 2 * math.pi + math.pi / 4
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.17, radius2=0.01, depth=0.5,
                                        location=(L / 2 + 0.2, math.cos(a) * 0.3, math.sin(a) * 0.3))
        p = bpy.context.active_object; p.data.materials.append(m['red'])
        p.rotation_euler = (0, math.radians(90), 0); p.rotation_euler.rotate_axis('X', a)
        p.rotation_euler.rotate_axis('Y', math.radians(-35))
        bpy.ops.object.shade_smooth()
    flesh = grime_material('flesh2', COL['flesh'], rough=0.25, sss=0.35, coat=0.9, veins=(3.2, (0.28, 0.03, 0.06)))
    chitin = grime_material('chitin2', COL['chitin'], rough=0.3, coat=0.7)
    dark = grime_material('dark2', COL['dark'], rough=0.3, coat=0.6, grime=0.6)
    maw = grime_material('maw2', (0.30, 0.02, 0.03), rough=0.15, grime=0.5, sss=0.4, coat=1.0)
    ellipsoid((L / 2 + 0.15, 0, 0), (0.3, 0.3, 0.3), flesh)
    h = ellipsoid((L / 2 + 0.45, 0, 0.02), (0.3, 0.27, 0.26), chitin); lumpy(h, 0.02)
    ellipsoid((L / 2 + 0.7, 0, 0.02), (0.08, 0.15, 0.13), maw)
    for k in (-0.6, 0, 0.6):
        cone((L / 2 + 0.75, math.sin(k) * 0.2, math.cos(k) * 0.05 + 0.02), (0, math.radians(90), k * 0.6), 0.06, 0.32, dark)
    goo = grime_material('goo2', (0.50, 0.55, 0.14), rough=0.03, grime=0.35, sss=0.3, coat=1.0, transmission=0.25, ior=1.3, bumpk=0.4)
    for k in range(4):
        ellipsoid((L / 2 - 0.05 - k * 0.08, 0.05 * k, -0.3 - k * 0.05), (0.05, 0.05, 0.14 + k * 0.03), goo, seg=16)


def rocket_bio(m):
    """An organic rocket: chitin-plated casing grown around the larva, steel fins bolted on."""
    L = 2.4
    rocket_body(m, length=L, nose=False, color='dark')
    chitin = grime_material('chitin3', COL['chitin'], rough=0.3, coat=0.7)
    flesh = grime_material('flesh3', COL['flesh'], rough=0.25, sss=0.35, coat=0.9, veins=(3.2, (0.28, 0.03, 0.06)))
    for k in range(7):  # overlapping plates along the body
        x = -L / 2 + 0.55 + k * 0.3
        p = ellipsoid((x, 0, 0.02), (0.2, 0.37, 0.37), chitin); lumpy(p, 0.02)
        ellipsoid((x + 0.15, 0, 0), (0.08, 0.34, 0.34), flesh, seg=24)
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=0.38, radius2=0.0, depth=0.9, location=(L / 2 + 0.4, 0, 0), rotation=(0, math.radians(90), 0))
    n = bpy.context.active_object; n.data.materials.append(chitin); bpy.ops.object.shade_smooth(); lumpy(n, 0.03)
    darkc = grime_material('dark3', COL['dark'], rough=0.3, coat=0.6, grime=0.6)
    for k in range(6):  # spikes along the top and sides
        a = math.radians(90) + (k % 3 - 1) * math.radians(50)
        x = -0.4 + k * 0.38
        cone((x, math.cos(a) * 0.42, math.sin(a) * 0.42), (math.radians(90) - a, 0, 0), 0.06, 0.3, darkc)
    pus = grime_material('pus3', (0.78, 0.66, 0.22), rough=0.12, grime=0.4, sss=0.6, coat=1.0)
    import random
    rnd = random.Random(5)
    for _ in range(14):
        a = rnd.uniform(0, 2 * math.pi); x = rnd.uniform(-0.6, 1.6)
        rr = 0.36 if x < L / 2 else 0.36 * max(0.2, 1 - (x - L / 2) / 0.9)
        ellipsoid((x, math.cos(a) * rr, math.sin(a) * rr), (0.05, 0.05, 0.05), pus, seg=16)


OPTIONS = {'canister-std': lambda m: canister(m, False), 'canister-cryo': lambda m: canister(m, True),
           'jar-std': lambda m: jar(m, False), 'jar-cryo': lambda m: jar(m, True),
           'hex-std': lambda m: hexcell(m, False), 'hex-cryo': lambda m: hexcell(m, True),
           'ward-canister': ward_canister, 'ward-pod': ward_pod, 'ward-hex': ward_hex,
           'rocket-glass': rocket_glass, 'rocket-tint': rocket_tintable, 'rocket-window': rocket_window, 'rocket-cage': rocket_cage, 'rocket-porthole': rocket_porthole, 'rocket-burst': rocket_burst, 'rocket-bio': rocket_bio}

if __name__ == '__main__':
    B.reset(); B.lights(); B.camera()
    m = mats()
    fn = OPTIONS[ITEM]
    if ITEM.startswith('rocket'):
        # rockets lie diagonally, nose to the top right, like vanilla ammo icons
        group(lambda: fn(m), loc=(0, 0, 0.6), rot=(0, math.radians(-12), math.radians(40)))
    else:
        fn(m)
    import os
    part = os.environ.get('PART')
    if part:
        isolate(part)
    B.render_to(OUT)
