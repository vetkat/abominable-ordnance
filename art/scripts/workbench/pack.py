import sys, json
from PIL import Image
S=0.6
def pack(src, fw, fh, cols, count, out, s=S, q=82):
    im=Image.open(src).convert('RGBA')
    nw,nh=round(fw*s),round(fh*s)
    rows=(count+cols-1)//cols
    o=Image.new('RGBA',(nw*cols,nh*rows),(0,0,0,0))
    for i in range(count):
        sx,sy=(i%cols)*fw,(i//cols)*fh
        fr=im.crop((sx,sy,sx+fw,sy+fh)).resize((nw,nh),Image.LANCZOS)
        o.paste(fr,((i%cols)*nw,(i//cols)*nh))
    o.save(out,'WEBP',quality=q,method=6)
    return {'file':out.split('/')[-1],'fw':nw,'fh':nh,'cols':cols,'count':count,'src_w':fw,'src_h':fh}
A='/home/claude/wb/assets/'
M='/home/claude/simonbrodtmann/mod-framework/mf-buildings-graphics-1/graphics/pathogen-lab/'
N='/home/claude/nullius-visual-overhaul/graphics/entity/oxidizer/'
P='/home/claude/panglia/simulation_chamber/'
man={}
man['pod']={
 'anim':pack(M+'pathogen-lab-animation.png',500,500,8,60,A+'pod-anim.webp'),
 'emis':pack(M+'pathogen-lab-emission.png',500,500,8,60,A+'pod-emis.webp'),
 'shadow':pack(M+'pathogen-lab-shadow.png',800,700,1,1,A+'pod-shadow.webp'),
}
man['inc']={
 'anim':pack(N+'oxidizer-base.png',275,313,8,60,A+'inc-anim.webp'),
 'emis':pack(N+'oxidizer-emission.png',280,320,9,60,A+'inc-emis.webp'),
 'shadow':pack(N+'oxidizer-shadow.png',372,280,1,1,A+'inc-shadow.webp'),
}
man['cham']={'anim':pack(P+'simulation_chamber_base.png',512,512,1,1,A+'cham-base.webp'),
 'shadow':pack(P+'simulation_chamber_shadow.png',512,512,1,1,A+'cham-shadow.webp'),
 'glow':pack(P+'simulation_chamber_glow.png',512,512,1,1,A+'cham-glow.webp'),
 'screen':pack(P+'simulation_chamber_screen_anim.png',64,64,32,255,A+'cham-screen.webp',s=1),
}
for k in range(1,5): man['cham']['layer%d'%k]=pack(P+'layer%d.png'%k,512,512,1,1,A+'cham-layer%d.webp'%k)
json.dump(man,open('/home/claude/wb/manifest.json','w'),indent=1)
