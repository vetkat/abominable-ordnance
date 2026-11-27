from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont
import colorsys
P='/home/claude/panglia/simulation_chamber/'
TINT={'biter':(214,120,60),'spitter':(150,190,70)}
def crop(k):
    im=Image.open(P+f'layer{k}.png').convert('RGBA'); return im.crop(im.getbbox())
def tint(im,col,mix=0.75):
    px=im.load(); out=im.copy(); o=out.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=px[x,y]
            if not a: continue
            l=(0.3*r+0.59*g+0.11*b)/255
            tr,tg,tb=[min(255,int(c*l*1.7)) for c in col]
            o[x,y]=(int(r*(1-mix)+tr*mix),int(g*(1-mix)+tg*mix),int(b*(1-mix)+tb*mix),a)
    return out
def fit(im,size=256,pad=0.08):
    s=size*(1-2*pad)/max(im.size); im=im.resize((max(1,int(im.width*s)),max(1,int(im.height*s))),Image.LANCZOS)
    c=Image.new('RGBA',(size,size)); c.alpha_composite(im,((size-im.width)//2,(size-im.height)//2)); return c
def vial(creature,col,size=256):
    S=4; W=size*S; c=Image.new('RGBA',(W,W)); d=ImageDraw.Draw(c)
    x0,x1,y0,y1=int(W*0.28),int(W*0.72),int(W*0.14),int(W*0.88)
    r=int((x1-x0)*0.45)
    liq=tuple(int(v*0.55) for v in col)
    d.rounded_rectangle([x0,y0,x1,y1],radius=r,fill=liq+(150,))
    cr=creature.copy(); s=(x1-x0)*0.92/max(cr.size); cr=cr.resize((int(cr.width*s),int(cr.height*s)),Image.LANCZOS)
    c.alpha_composite(cr,((x0+x1-cr.width)//2,(y0+y1-cr.height)//2+int(W*0.03)))
    gl=Image.new('RGBA',(W,W)); g=ImageDraw.Draw(gl)
    g.rounded_rectangle([x0,y0,x1,y1],radius=r,outline=(225,240,235,170),width=int(W*0.018))
    g.rounded_rectangle([x0+int(W*0.05),y0+int(W*0.1),x0+int(W*0.09),y1-int(W*0.16)],radius=int(W*0.02),fill=(255,255,255,90))
    c.alpha_composite(gl)
    for (ya,yb) in [(y0-int(W*0.05),y0+int(W*0.06)),(y1-int(W*0.06),y1+int(W*0.05))]:
        d.rounded_rectangle([x0-int(W*0.03),ya,x1+int(W*0.03),yb],radius=int(W*0.02),fill=(92,88,82,255),outline=(40,38,35,255),width=int(W*0.01))
        d.rectangle([x0-int(W*0.02),ya+int(W*0.015),x1+int(W*0.02),ya+int(W*0.03)],fill=(160,155,145,255))
    return c.resize((size,size),Image.LANCZOS)
def shadow(im):
    a=im.split()[3].filter(ImageFilter.GaussianBlur(5)); s=Image.new('RGBA',im.size,(0,0,0,0)); s.putalpha(a.point(lambda v:int(v*0.55)))
    out=Image.new('RGBA',im.size); out.alpha_composite(s,(4,6)); out.alpha_composite(im); return out
opts={}
for sp,col in TINT.items():
    opts[('A',sp)]=shadow(fit(tint(crop(2),col)))
    opts[('B',sp)]=shadow(fit(tint(crop(3),col)))
    opts[('C',sp)]=shadow(fit(tint(crop(4),col)))
    opts[('D',sp)]=shadow(vial(tint(crop(3),col),col))
names={'A':'A · Curled embryo (stage 2)','B':'B · Young larva (stage 3)','C':'C · Grown larva (stage 4)','D':'D · Larva in an ammo vial'}
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',20)
small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',14)
RH=230; W=1000
sheet=Image.new('RGB',(W,40+RH*4),(34,31,26)); d=ImageDraw.Draw(sheet)
d.text((300,10),'Biter',fill=(230,225,218),font=font); d.text((680,10),'Spitter',fill=(230,225,218),font=font)
def slot(img,sz,x,y):
    pad=6; d.rectangle([x,y,x+sz+2*pad,y+sz+2*pad],fill=(49,48,49),outline=(20,20,20)); 
    sheet.paste(img.resize((sz,sz),Image.LANCZOS),(x+pad,y+pad),img.resize((sz,sz),Image.LANCZOS))
for i,k in enumerate('ABCD'):
    y=40+i*RH
    d.text((14,y+10),names[k],fill=(240,200,120),font=font)
    for j,sp in enumerate(['biter','spitter']):
        x=230+j*380; im=opts[(k,sp)]
        slot(im,160,x,y+40); slot(im,64,x+190,y+40); slot(im,32,x+280,y+40)
        im.save(f'larva-{k}-{sp}.png')
    d.text((14,y+40),'big preview · 64 px icon ·\n32 px in an inventory slot',fill=(180,175,168),font=small)
sheet.save('/home/claude/preview/larva-icon-options.png')
