"""Render the larva, egg and loaded-larva icons in Blender (Cycles), lit like Factorio's item icons.
Usage: python blender_icons.py <item> <species> <out.png>"""
import sys, math
import bpy
from mathutils import Vector

ITEM, SPECIES, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
VARIANT = sys.argv[4] if len(sys.argv) > 4 else ''
RES = 640

COL = {
    'biter':   dict(flesh=(0.78, 0.36, 0.10), chitin=(0.17, 0.07, 0.03), dark=(0.07, 0.035, 0.02), egg=(0.62, 0.50, 0.30), vein=(0.22, 0.07, 0.03), liquid=(0.30, 0.13, 0.05)),
    # pale, neutral larva for the tintable rocket layers; species colour comes from the icon tint
    'neutral': dict(flesh=(0.66, 0.62, 0.56), chitin=(0.22, 0.21, 0.2), dark=(0.07, 0.07, 0.065), egg=(0.6, 0.58, 0.52), vein=(0.2, 0.18, 0.17), liquid=(0.25, 0.24, 0.22)),
    'spitter': dict(flesh=(0.48, 0.52, 0.18), chitin=(0.08, 0.11, 0.03), dark=(0.035, 0.05, 0.015), egg=(0.50, 0.54, 0.30), vein=(0.10, 0.14, 0.03), liquid=(0.16, 0.22, 0.05)),
}[SPECIES]
VARIANTS = {
    'orange': dict(flesh=(0.78, 0.36, 0.10), chitin=(0.17, 0.07, 0.03)),
    'red': dict(flesh=(0.62, 0.20, 0.14), chitin=(0.17, 0.045, 0.04)),
}
COL.update(VARIANTS.get(VARIANT, {}))


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 96
    sc.cycles.transmission_bounces = 12; sc.cycles.max_bounces = 16; sc.cycles.transparent_max_bounces = 16
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    sc.view_settings.exposure = -0.55
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    world = bpy.data.worlds.new('w'); sc.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.32, 0.30, 0.28, 1); bg.inputs[1].default_value = 0.25
    return sc


def lights():
    def sun(name, rot, energy, color):
        d = bpy.data.lights.new(name, 'SUN'); d.energy = energy; d.color = color; d.angle = math.radians(8)
        o = bpy.data.objects.new(name, d); bpy.context.collection.objects.link(o)
        o.rotation_euler = [math.radians(a) for a in rot]
    sun('key', (40, -10, -35), 4.2, (1.0, 0.95, 0.88))      # from the top left, like the game's icons
    sun('fill', (60, 0, 140), 0.45, (0.75, 0.82, 1.0))
    sun('rim', (-60, 0, 20), 2.2, (1.0, 0.85, 0.7))


def camera():
    cam = bpy.data.cameras.new('cam'); cam.type = 'ORTHO'; cam.ortho_scale = 4.4
    o = bpy.data.objects.new('cam', cam); bpy.context.collection.objects.link(o)
    o.location = (0, -6.2, 7.4)
    o.rotation_euler = (math.radians(40), 0, 0)
    bpy.context.scene.camera = o


def node(nt, kind, loc=(0, 0), **inputs):
    n = nt.nodes.new(kind); n.location = loc
    for k, v in inputs.items():
        n.inputs[k].default_value = v
    return n


def grime_material(name, base, rough=0.45, grime=1.0, sss=0.0, metallic=0.0, rust=None, veins=None, transmission=0.0, alpha=1.0, coat=0.3, top=None, ior=1.35, bumpk=1.0):
    """Principled material with mottled colour, dirt in a noise mask, wet/dry roughness and bump."""
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; bsdf = nt.nodes['Principled BSDF']
    tc = node(nt, 'ShaderNodeTexCoord', (-1400, 0))
    def noise(scale, detail=8, rough_=0.6, loc=(-1100, 0)):
        n = node(nt, 'ShaderNodeTexNoise', loc, Scale=scale, Detail=detail, Roughness=rough_)
        nt.links.new(tc.outputs['Object'], n.inputs['Vector']); return n
    big, mid, fine = noise(1.6, loc=(-1100, 300)), noise(6.0, loc=(-1100, 0)), noise(38.0, 4, 0.7, loc=(-1100, -300))
    # mottled base: base colour darkened/lightened by two noise scales
    mot = node(nt, 'ShaderNodeMixRGB', (-800, 300)); mot.blend_type = 'MULTIPLY'
    mot.inputs['Fac'].default_value = 0.85 * grime
    mot.inputs['Color1'].default_value = (*base, 1)
    ramp = node(nt, 'ShaderNodeValToRGB', (-950, 300))
    ramp.color_ramp.elements[0].position = 0.3; ramp.color_ramp.elements[0].color = (0.55, 0.55, 0.55, 1)
    ramp.color_ramp.elements[1].position = 0.75; ramp.color_ramp.elements[1].color = (1.35, 1.3, 1.2, 1)
    nt.links.new(big.outputs['Fac'], ramp.inputs['Fac']); nt.links.new(ramp.outputs['Color'], mot.inputs['Color2'])
    col = mot.outputs['Color']
    if veins:
        vn = node(nt, 'ShaderNodeTexNoise', (-1100, 600), Scale=veins[0], Detail=6, Roughness=0.55)
        nt.links.new(tc.outputs['Object'], vn.inputs['Vector'])
        vr = node(nt, 'ShaderNodeValToRGB', (-900, 600))
        e = vr.color_ramp.elements
        w = veins[2] if len(veins) > 2 else 0.012
        e[0].position = 0.5 - w; e[0].color = (0, 0, 0, 1)
        e[1].position = 0.5; e[1].color = (1, 1, 1, 1)
        e3 = e.new(0.5 + w); e3.color = (0, 0, 0, 1)
        nt.links.new(vn.outputs['Fac'], vr.inputs['Fac'])
        vm = node(nt, 'ShaderNodeMixRGB', (-650, 450)); vm.inputs['Color2'].default_value = (*veins[1], 1)
        nt.links.new(vr.outputs['Color'], vm.inputs['Fac']); nt.links.new(col, vm.inputs['Color1']); col = vm.outputs['Color']
    if top:  # chitin on the upward-facing surfaces (the back), flesh below
        geo = node(nt, 'ShaderNodeNewGeometry', (-1100, 800))
        sep = node(nt, 'ShaderNodeSeparateXYZ', (-950, 800)); nt.links.new(geo.outputs['Normal'], sep.inputs[0])
        tr = node(nt, 'ShaderNodeValToRGB', (-800, 800))
        tr.color_ramp.elements[0].position = top[1]; tr.color_ramp.elements[1].position = top[1] + 0.12
        tm = node(nt, 'ShaderNodeMath', (-700, 900)); tm.operation = 'ADD'
        nt.links.new(sep.outputs['Z'], tm.inputs[0]); tm.inputs[1].default_value = 0.0
        nt.links.new(tm.outputs[0], tr.inputs['Fac'])
        tmix = node(nt, 'ShaderNodeMixRGB', (-600, 700)); tmix.inputs['Color2'].default_value = (*top[0], 1)
        nt.links.new(tr.outputs['Color'], tmix.inputs['Fac']); nt.links.new(col, tmix.inputs['Color1']); col = tmix.outputs['Color']
    if rust:
        rr = node(nt, 'ShaderNodeValToRGB', (-900, -600))
        rr.color_ramp.elements[0].position = 0.55; rr.color_ramp.elements[1].position = 0.62
        n2 = noise(3.2, 10, 0.7, loc=(-1100, -600)); nt.links.new(n2.outputs['Fac'], rr.inputs['Fac'])
        rm = node(nt, 'ShaderNodeMixRGB', (-650, -450)); rm.inputs['Color2'].default_value = (*rust, 1)
        nt.links.new(rr.outputs['Color'], rm.inputs['Fac']); nt.links.new(col, rm.inputs['Color1']); col = rm.outputs['Color']
    # dirt: dark brown where the mid noise is high
    dr = node(nt, 'ShaderNodeValToRGB', (-900, 0))
    dr.color_ramp.elements[0].position = 0.58; dr.color_ramp.elements[1].position = 0.72
    nt.links.new(mid.outputs['Fac'], dr.inputs['Fac'])
    dm = node(nt, 'ShaderNodeMixRGB', (-450, 150)); dm.inputs['Color2'].default_value = (0.05, 0.035, 0.022, 1)
    ao = node(nt, 'ShaderNodeAmbientOcclusion', (-1100, -150)); ao.inputs['Distance'].default_value = 0.35
    inv = node(nt, 'ShaderNodeMath', (-900, -150)); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1.0
    nt.links.new(ao.outputs['AO'], inv.inputs[1])
    blot = node(nt, 'ShaderNodeMath', (-800, -50)); blot.operation = 'MULTIPLY'; blot.inputs[1].default_value = 0.55
    nt.links.new(dr.outputs['Color'], blot.inputs[0])
    both = node(nt, 'ShaderNodeMath', (-700, -100)); both.operation = 'ADD'; both.use_clamp = True
    nt.links.new(blot.outputs[0], both.inputs[0])
    aok = node(nt, 'ShaderNodeMath', (-800, -200)); aok.operation = 'MULTIPLY'; aok.inputs[1].default_value = 1.6
    nt.links.new(inv.outputs[0], aok.inputs[0]); nt.links.new(aok.outputs[0], both.inputs[1])
    dfac = node(nt, 'ShaderNodeMath', (-600, 0)); dfac.operation = 'MULTIPLY'; dfac.inputs[1].default_value = 1.0 * grime
    nt.links.new(both.outputs[0], dfac.inputs[0]); nt.links.new(dfac.outputs[0], dm.inputs['Fac'])
    nt.links.new(col, dm.inputs['Color1'])
    nt.links.new(dm.outputs['Color'], bsdf.inputs['Base Color'])
    # roughness: wet patches and dry dirt
    rmap = node(nt, 'ShaderNodeMapRange', (-450, -150))
    rmap.inputs['To Min'].default_value = rough * 0.45; rmap.inputs['To Max'].default_value = min(1, rough * 1.8)
    nt.links.new(big.outputs['Fac'], rmap.inputs['Value'])
    nt.links.new(rmap.outputs['Result'], bsdf.inputs['Roughness'])
    # bump from fine + mid noise
    bump = node(nt, 'ShaderNodeBump', (-250, -350), Strength=0.6 * grime * bumpk, Distance=0.05)
    add = node(nt, 'ShaderNodeMath', (-450, -350)); add.operation = 'ADD'
    nt.links.new(fine.outputs['Fac'], add.inputs[0]); nt.links.new(mid.outputs['Fac'], add.inputs[1])
    nt.links.new(add.outputs[0], bump.inputs['Height']); nt.links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Coat Weight'].default_value = coat
    bsdf.inputs['Coat Roughness'].default_value = 0.25
    if sss:
        bsdf.inputs['Subsurface Weight'].default_value = sss
        bsdf.inputs['Subsurface Radius'].default_value = (0.4, 0.2, 0.1)
        bsdf.inputs['Subsurface Scale'].default_value = 0.08
    if transmission:
        bsdf.inputs['Transmission Weight'].default_value = transmission
        bsdf.inputs['IOR'].default_value = ior
    if alpha < 1:
        bsdf.inputs['Alpha'].default_value = alpha
    return m


def ellipsoid(loc, scale, mat, rot=(0, 0, 0), seg=48):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, location=loc, rotation=rot)
    o = bpy.context.active_object; o.scale = scale
    bpy.ops.object.shade_smooth(); o.data.materials.append(mat)
    return o


def cone(loc, rot, r, depth, mat):
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=r, radius2=r * 0.08, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object; bpy.ops.object.shade_smooth(); o.data.materials.append(mat)
    return o


def lumpy(o, strength=0.05, scale=1.4):
    tex = bpy.data.textures.new('lump', 'CLOUDS'); tex.noise_scale = scale
    sub = o.modifiers.new('sub', 'SUBSURF'); sub.levels = 2; sub.render_levels = 2
    d = o.modifiers.new('disp', 'DISPLACE'); d.texture = tex; d.strength = strength; d.mid_level = 0.5


def larva(origin=(0, 0, 0), size=1.0, spikes=True, gross=False):
    """C-shaped larva: one segmented tube (ring bulges from the curve radius), chitin on its back,
    dorsal spikes on every other ring, stubby legs and a mandibled chitin head."""
    ox, oy, oz = origin
    if gross:
        flesh = grime_material('flesh', COL['flesh'], rough=0.25, sss=0.35, coat=0.9, top=(COL['chitin'], 0.8), veins=(3.2, (0.28, 0.03, 0.06)))
    else:
        flesh = grime_material('flesh', COL['flesh'], rough=0.35, sss=0.2, coat=0.5, top=(COL['chitin'], 0.78))
    chitin = grime_material('chitin', COL['chitin'], rough=0.3, coat=0.7)
    dark = grime_material('dark', COL['dark'], rough=0.3, coat=0.6, grime=0.6)
    a0, a1, R = math.radians(210), math.radians(-40), 1.0 * size
    rings, steps = 9, 180
    cu = bpy.data.curves.new('body', 'CURVE'); cu.dimensions = '3D'
    cu.bevel_depth = 1.0; cu.bevel_resolution = 10; cu.use_fill_caps = True
    sp = cu.splines.new('POLY'); sp.points.add(steps - 1)
    def path(t):
        a = a0 + (a1 - a0) * t
        return a, ox + math.cos(a) * R, oy + math.sin(a) * R * 0.92
    def base_r(t):
        # pointed tail, fat middle, thick neck under the head
        return 0.36 * size * math.sin(math.pi / 2 * min(1.0, 0.04 + t / 0.32)) * (1 - 0.18 * t)
    for k in range(steps):
        t = k / (steps - 1)
        a, x, y = path(t)
        rr = base_r(t) * (1 + 0.13 * math.cos(2 * math.pi * rings * t))
        sp.points[k].co = (x, y, oz + base_r(t) * 0.85, 1)
        sp.points[k].radius = rr
    o = bpy.data.objects.new('body', cu); bpy.context.collection.objects.link(o)
    o.data.materials.append(flesh)
    bpy.context.view_layer.objects.active = o; o.select_set(True)
    bpy.ops.object.convert(target='MESH'); body = bpy.context.active_object
    bpy.ops.object.shade_smooth()
    body.scale = (1, 1, 0.82)
    lumpy(body, 0.035 * size, 0.5)
    # head at the end of the tube
    a, x, y = path(1.0)
    tang = a - math.pi / 2
    r = base_r(1.0) * 1.12
    hx, hy = x + math.cos(tang) * r * 0.55, y + math.sin(tang) * r * 0.55
    head = ellipsoid((hx, hy, oz + r * 0.75), (r * 1.0, r * 0.95, r * 0.85), chitin)
    lumpy(head, 0.03 * size)
    for k in (-0.6, 0, 0.6):
        d = tang + k
        cone((hx + math.cos(d) * r * 0.9, hy + math.sin(d) * r * 0.9, oz + r * 0.7), (math.radians(90), 0, d - math.pi / 2), r * 0.22, r * 0.95, dark)
    for j in range(rings):
        t = (j + 0.0) / rings
        if t < 0.1:
            continue
        a, x, y = path(t)
        r = base_r(t)
        tang = a - math.pi / 2
        plate = ellipsoid((x + math.cos(a) * r * 0.12, y + math.sin(a) * r * 0.12, oz + base_r(t) * 0.85 * 0.82 + r * 0.6),
                          (r * 0.46, r * 1.12, r * 0.2), chitin, rot=(0, 0, tang))
        lumpy(plate, 0.02 * size)
        if spikes and j % 2 == 0:
            cone((x + math.cos(a) * r * 0.35, y + math.sin(a) * r * 0.35, oz + r * 1.55), (math.radians(-15), 0, a - math.pi / 2), r * 0.22, r * 1.05, dark)
        if 0.2 < t < 0.85:
            lx, ly = x - math.cos(a) * r * 0.9, y - math.sin(a) * r * 0.9
            cone((lx, ly, oz + r * 0.3), (math.radians(120), 0, a + math.pi / 2), r * 0.13, r * 0.55, dark)
    if not gross:
        return
    import random
    rnd = random.Random(11)
    pus = grime_material('pus', (0.78, 0.66, 0.22), rough=0.12, grime=0.4, sss=0.6, coat=1.0)
    goo = grime_material('goo', (0.50, 0.55, 0.14), rough=0.03, grime=0.35, sss=0.3, coat=1.0, transmission=0.25, ior=1.3, bumpk=0.4)
    maw_m = grime_material('maw', (0.30, 0.02, 0.03), rough=0.15, grime=0.5, sss=0.4, coat=1.0)
    tooth = grime_material('tooth', (0.72, 0.64, 0.42), rough=0.3, grime=0.7, coat=0.4)
    # pustules on the sides and back
    for _ in range(48):
        t = rnd.uniform(0.12, 0.95)
        a, x, y = path(t); r = base_r(t)
        phi = rnd.uniform(-0.3, 2.2)
        zc = (oz + r * 0.85) * 0.82
        px = x + math.cos(a) * math.cos(phi) * r * 0.95
        py = y + math.sin(a) * math.cos(phi) * r * 0.95
        pz = zc + math.sin(phi) * r * 0.82 * 0.95
        pr = r * rnd.uniform(0.12, 0.26)
        b = ellipsoid((px, py, pz), (pr, pr, pr * 0.85), pus, seg=20)
    # slime puddle along the body, and strands dripping into it
    for k in range(7):
        t = 0.08 + k * 0.14
        a, x, y = path(t); r = base_r(t)
        g = ellipsoid((x - math.cos(a) * r * 0.35, y - math.sin(a) * r * 0.35, 0.0), (r * 1.25, r * 1.05, 0.07 * size), goo, rot=(0, 0, a), seg=32)
        lumpy(g, 0.07 * size, 0.35)
    for k in range(5):
        t = 0.25 + k * 0.15
        a, x, y = path(t); r = base_r(t)
        sx, sy = x - math.cos(a) * r * 0.75, y - math.sin(a) * r * 0.75
        ellipsoid((sx, sy, r * 0.32), (0.035 * size, 0.035 * size, r * 0.34), goo, seg=16)
    # open maw with a ring of teeth at the front of the head
    a, x, y = path(1.0); tang = a - math.pi / 2; r = base_r(1.0) * 1.12
    hx, hy = x + math.cos(tang) * r * 0.55, y + math.sin(tang) * r * 0.55
    mx, my = hx + math.cos(tang) * r * 0.78, hy + math.sin(tang) * r * 0.78
    ellipsoid((mx, my, oz + r * 0.75), (r * 0.32, r * 0.55, r * 0.5), maw_m, rot=(0, 0, tang), seg=32)
    for k in range(8):
        d = k / 8 * 2 * math.pi
        tx = mx + math.cos(tang) * r * 0.12 - math.sin(tang) * math.cos(d) * r * 0.32
        ty = my + math.sin(tang) * r * 0.12 + math.cos(tang) * math.cos(d) * r * 0.32
        tz = oz + r * 0.72 + math.sin(d) * r * 0.28
        cone((tx + math.cos(tang) * r * 0.1, ty + math.sin(tang) * r * 0.1, tz + r * 0.03), (math.radians(90), 0, tang - math.pi / 2), r * 0.08, r * 0.34, tooth)


def slime(loc, scale, color):
    m = grime_material('slime', color, rough=0.08, grime=0.3, coat=1.0, transmission=0.3)
    o = ellipsoid(loc, scale, m, seg=32); lumpy(o, 0.06, 0.8)
    return o


def build():
    if ITEM == 'larva':
        larva(gross=True)
    elif ITEM == 'egg':
        larva(origin=(0.1, 0.0, 0.55), size=0.62, spikes=False)
        mem = grime_material('membrane', COL['egg'], rough=0.08, grime=0.5, veins=(2.2, COL['vein'], 0.025), transmission=0.92, coat=0.5, ior=1.04, bumpk=0.15)
        egg = ellipsoid((0, 0, 0.95), (1.15, 1.15, 1.45), mem, rot=(math.radians(-35), 0, math.radians(20)), seg=64)
        lumpy(egg, 0.05, 1.0)
        slime((0.1, -0.2, 0.05), (1.0, 0.8, 0.12), COL['vein'])
    else:  # loaded larva in a capsule
        metal = grime_material('metal', (0.32, 0.31, 0.29), rough=0.5, metallic=0.85, rust=(0.24, 0.10, 0.04), coat=0.1)
        darkm = grime_material('darkmetal', (0.12, 0.115, 0.11), rough=0.55, metallic=0.7, rust=(0.18, 0.08, 0.03), coat=0.1)
        bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=1.55, depth=0.4, location=(0, 0, 0.2))
        base = bpy.context.active_object; base.data.materials.append(metal)
        bev = base.modifiers.new('bev', 'BEVEL'); bev.width = 0.08; bev.segments = 4
        bpy.ops.object.shade_smooth()
        bpy.ops.mesh.primitive_torus_add(major_radius=1.38, minor_radius=0.12, location=(0, 0, 0.42))
        ring = bpy.context.active_object; ring.data.materials.append(darkm); bpy.ops.object.shade_smooth()
        for k in range(8):
            a = k / 8 * 2 * math.pi + 0.2
            ellipsoid((math.cos(a) * 1.38, math.sin(a) * 1.38, 0.55), (0.09, 0.09, 0.06), metal, seg=16)
        liquid = grime_material('liquid', COL['liquid'], rough=0.2, grime=0.5, sss=0.3, coat=0.4)
        ellipsoid((0, 0, 0.34), (1.25, 1.25, 0.08), liquid)
        larva(origin=(0.08, 0.0, 0.36), size=0.78, spikes=False)
        glass = grime_material('glass', (0.96, 0.98, 0.95), rough=0.05, grime=0.3, transmission=1.0, coat=0.3, ior=1.05, bumpk=0.1)
        dome = ellipsoid((0, 0, 0.42), (1.3, 1.3, 0.95), glass, seg=64)
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='DESELECT'); bpy.ops.object.mode_set(mode='OBJECT')
        for v in dome.data.vertices:  # keep the upper half only
            v.select = v.co.z < -0.02
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.delete(type='VERT'); bpy.ops.object.mode_set(mode='OBJECT')
        sol = dome.modifiers.new('thick', 'SOLIDIFY'); sol.thickness = 0.05
        # a band of grime around the foot of the dome so the glass reads as glass
        film = grime_material('film', (0.25, 0.22, 0.16), rough=0.6, grime=1.0, alpha=0.55, coat=0.0)
        bpy.ops.mesh.primitive_torus_add(major_radius=1.26, minor_radius=0.07, location=(0, 0, 0.5))
        band = bpy.context.active_object; band.scale = (1, 1, 1.6); band.data.materials.append(film); bpy.ops.object.shade_smooth()


def render_to(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    reset(); lights(); camera(); build(); render_to(OUT)
