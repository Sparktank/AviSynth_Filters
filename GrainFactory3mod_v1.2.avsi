##################################################
###                                            ###
###              GrainFactoryLite              ###
###                                            ###
###      by 06_taro - astrataro@gmail.com      ###
###                                            ###
###            v1.2 - 06 April 2012            ###
###                                            ###
##################################################
###
### Luma adaptive grain generating filter in 8-bit precision
###
### Based on Didée's GrainFactory3 script
### 
###
### +-------------+
### |  CHANGELOG  |
### +-------------+
###
### v1.2 - 06 April 2012
###      - Added support for generating f3kdb based grain ( set negative value for g*str to use f3kdb based grain )
###
### v1.1 - 13 March 2012
###      - Add chroma grain support
###      - Add RemoveGrain requirement
###      - Use float for "ontop_grain" instead of int
###      - Synchronize version number with GrainFactoryLite
###
### v0.3 - 28 May 2011
###      - Split "constant" into "g*const"
###
### v0.2 - 27 May 2011
###      - Use float for "g*str" instead of int
###
### v0.1 - 22 May 2011
###      - First release, able to generate completely constant grain
###
### +---------+
### |  USAGE  |
### +---------+
###
### GrainFactory3mod()
###
### See below for explanation of parameters
###
### +----------------+
### |  REQUIREMENTS  |
### +----------------+
###
### -> AddGrainC         [v1.6.1]
### -> RemoveGrain      [v1.0pre]
### -> MaskTools2       [v2.0a48]
### -> f3kdb             [v1.5.0]
###

function GrainFactory3mod(clip clp,
 \                        float "g1str",   float "g2str",   float "g3str",
 \                        float "g1cstr",  float "g2cstr",  float "g3cstr",
 \                        int   "g1shrp",  int   "g2shrp",  int   "g3shrp",
 \                        float "g1size",  float "g2size",  float "g3size",
 \                        int   "g1tex",   int   "g2tex",   int   "g3tex",
 \                        bool  "g1const", bool  "g2const", bool  "g3const",
 \                        int   "th1",     int   "th2",     int   "th3",     int "th4",
 \                        int   "temp_avg",
 \                        float "ontop_grain",
 \                        float "ontop_cgrain",
 \                        bool  "ontop_const")
{

g1str        = default( g1str,         13 )  # [ 0 - ???] strength of luma grain / for dark areas
                                             # positive value for AddGrainC strength, negative value for f3kdb grain strength
g2str        = default( g2str,         15 )  # [ 0 - ???] strength of luma grain / for midtone areas
                                             # positive value for AddGrainC strength, negative value for f3kdb grain strength
g3str        = default( g3str,         25 )  # [ 0 - ???] strength of luma grain / for bright areas
                                             # positive value for AddGrainC strength, negative value for f3kdb grain strength
g1cstr       = default( g1cstr,         0 )  # [ 0 - ???] strength of chroma grain / for dark areas
                                             # positive value for AddGrainC strength, negative value for f3kdb grain strength
g2cstr       = default( g2cstr,         0 )  # [ 0 - ???] strength of chroma grain / for midtone areas
                                             # positive value for AddGrainC strength, negative value for f3kdb grain strength
g3cstr       = default( g3cstr,         0 )  # [ 0 - ???] strength of chroma grain / for bright areas
                                             # positive value for AddGrainC strength, negative value for f3kdb grain strength
g1shrp       = default( g1shrp,        60 )  # [ 0 - 100] sharpness of grain / for dark areas (NO EFFECT when g1size=1.0 !!)
g2shrp       = default( g2shrp,        66 )  # [ 0 - 100] sharpness of grain / for midtone areas (NO EFFECT when g2size=1.0 !!)
g3shrp       = default( g3shrp,        80 )  # [ 0 - 100] sharpness of grain / for bright areas (NO EFFECT when g3size=1.0 !!)
g1size       = default( g1size,      1.50 )  # [0.5 - 4.0] size of grain / for dark areas
g2size       = default( g2size,      1.20 )  # [0.5 - 4.0] size of grain / for mid-tone areas
g3size       = default( g3size,      0.90 )  # [0.5 - 4.0] size of grain / for bright areas
g1tex        = default( g1tex,          0 )  # [ 0 - 100] strength of "material texture" appearance
g2tex        = default( g2tex,          0 )  # [ 0 - 100] (in fact: 'bump' effect)
g3tex        = default( g3tex,          0 )  # [ 0 - 100] for dark / midtone / bright grain
g1const      = default( g1const,    false )  # AddGrainC "constant" parameter of grain / for dark areas
g2const      = default( g2const,    false )  # AddGrainC "constant" parameter of grain / for midtone areas
g3const      = default( g3const,    false )  # AddGrainC "constant" parameter of grain / for bright areas
temp_avg     = default( temp_avg,       0 )  # [ 0 - 100] percentage of noise's temporal averaging (NO EFFECT when g1const=g2const=g3const=true !!)
th1          = default( th1,           24 )  # start of dark->midtone  mixing zone
th2          = default( th2,           56 )  # end  of  dark->midtone  mixing zone
th3          = default( th3,          128 )  # start of midtone->bright  mixing zone
th4          = default( th4,          160 )  # end  of  midtone->bright  mixing zone
ontop_grain  = default( ontop_grain,    0 )  # [ 0 - ???] additional luma grain to put on top of prev. generated grain
                                             # positive value for AddGrainC strength, negative value for f3kdb grain strength
ontop_cgrain = Default( ontop_cgrain,   0 )  # [ 0 - ???] additional chroma grain to put on top of prev. generated grain
                                             # positive value for AddGrainC strength, negative value for f3kdb grain strength
ontop_const  = default( ontop_const, false)  # AddGrainC "constant" parameter of ontop clip

#-----------------------------------------------------------------------------------

o    = clp
ox   = o.width
oy   = o.height
oblr = o.RemoveGrain(19, -1)
sx1  = m4(ox/float(g1size))
sy1  = m4(oy/float(g1size))
sx1a = m4((ox+sx1)/2.0)
sy1a = m4((oy+sy1)/2.0)
sx2  = m4(ox/float(g2size))
sy2  = m4(oy/float(g2size))
sx2a = m4((ox+sx2)/2.0)
sy2a = m4((oy+sy2)/2.0)
sx3  = m4(ox/float(g3size))
sy3  = m4(oy/float(g3size))
sx3a = m4((ox+sx3)/2.0)
sy3a = m4((oy+sy3)/2.0)

b1   = g1shrp/(-50.0) + 1.0
b2   = g2shrp/(-50.0) + 1.0
b3   = g3shrp/(-50.0) + 1.0
b1a  = b1/2.0
b2a  = b2/2.0
b3a  = b3/2.0
c1   = (1.0-b1)/2.0
c2   = (1.0-b2)/2.0
c3   = (1.0-b3)/2.0
c1a  = (1.0-b1a)/2.0
c2a  = (1.0-b2a)/2.0
c3a  = (1.0-b3a)/2.0
T1a  = string(int(g1tex*1.28))
T1b  = string(128-int(g1tex*1.28))
T2a  = string(int(g2tex*1.28))
T2b  = string(128-int(g2tex*1.28))
T3a  = string(int(g3tex*1.28))
T3b  = string(128-int(g3tex*1.28))
th1str = string(th1)
th2str = string(th2)
th3str = string(th3)
th4str = string(th4)
tmpavg = temp_avg/100.0

chroma  = ( g1cstr == 0 ) && ( g2cstr == 0 ) && ( g3cstr == 0 ) ? false : true
ochroma = ( ontop_cgrain != 0 ) || chroma ? true : false

#-----------------------------------------------------------------------------------

BUMPKERNEL1 = T1a + " 0 0 0 " + T1b + " 0 0 0 0 128"
BUMPKERNEL2 = T2a + " 0 0 0 " + T2b + " 0 0 0 0 128"
BUMPKERNEL3 = T3a + " 0 0 0 " + T3b + " 0 0 0 0 128"

#-----------------------------------------------------------------------------------

grainlayer1 = blankclip(o, width=sx1, height=sy1, color_yuv=$808080)
grainlayer1 = (g1str>0 || g1cstr>0) ? grainlayer1.AddGrainC(g1str>0?g1str:0, g1cstr>0?g1cstr:0, 0, 0, constant=g1const)
\           : grainLayer1
grainLayer1 = (g1str<=-1 || g1cstr<=-1) ? grainLayer1.f3kdb(Y=0, Cb=0, Cr=0, grainY=g1str<=-1?Int(-g1str):0, grainC=g1cstr<=-1?Int(-g1cstr):0, dynamic_grain=!g1const, random_algo_grain=1)
\           : grainLayer1

grainlayer1 = (g1tex==0)
\           ? grainlayer1
\           : mt_makediff(grainlayer1,grainlayer1.mt_edge(BUMPKERNEL1, 0,255,0,0, U=chroma?3:1, V=chroma?3:1 ), U=chroma?3:1, V=chroma?3:1)

grainlayer1 = (g1size == 1.0 || sx1==ox && sy1==oy) ? grainlayer1
\           : (g1size > 1.5) ? grainlayer1.bicubicresize(sx1a,sy1a, b1a,c1a).bicubicresize(ox,oy, b1a,c1a)
\                            : grainlayer1.bicubicresize(ox,oy, b1,c1)

#-----------------------------------------------------------------------------------

grainlayer2 = blankclip(o, width=sx2, height=sy2, color_yuv=$808080)
grainlayer2 = (g2str>0 || g2cstr>0) ? grainlayer2.AddGrainC(g2str>0?g2str:0, g2cstr>0?g2cstr:0, 0, 0, constant=g2const)
\           : grainLayer2
grainLayer2 = (g2str<=-1 || g2cstr<=-1) ? grainLayer2.f3kdb(Y=0, Cb=0, Cr=0, grainY=g2str<=-1?Int(-g2str):0, grainC=g2cstr<=-1?Int(-g2cstr):0, dynamic_grain=!g2const, random_algo_grain=1)
\           : grainLayer2

grainlayer2 = (g2tex==0)
\           ? grainlayer2
\           : mt_makediff(grainlayer2,grainlayer2.mt_edge(BUMPKERNEL2, 0,255,0,0, U=chroma?3:1, V=chroma?3:1 ), U=chroma?3:1, V=chroma?3:1)

grainlayer2 = (g2size==1.0 || sx2==ox && sy2==oy) ? grainlayer2
\           : (g2size > 1.5) ? grainlayer2.bicubicresize(sx2a,sy2a, b2a,c2a).bicubicresize(ox,oy, b2a,c2a)
\                            : grainlayer2.bicubicresize(ox,oy, b2,c2)

#-----------------------------------------------------------------------------------

grainlayer3 = blankclip(o, width=sx3, height=sy3, color_yuv=$808080)
grainlayer3 = (g3str>0 || g3cstr>0) ? grainlayer3.AddGrainC(g3str>0?g3str:0, g3cstr>0?g3cstr:0, 0, 0, constant=g3const)
\           : grainLayer3
grainLayer3 = (g3str<=-1 || g3cstr<=-1) ? grainLayer3.f3kdb(Y=0, Cb=0, Cr=0, grainY=g3str<=-1?Int(-g3str):0, grainC=g3cstr<=-1?Int(-g3cstr):0, dynamic_grain=!g3const, random_algo_grain=1)
\           : grainLayer3

grainlayer3 = (g3tex==0)
\           ? grainlayer3
\           : mt_makediff(grainlayer3,grainlayer3.mt_edge(BUMPKERNEL2, 0,255,0,0, U=chroma?3:1, V=chroma?3:1 ), U=chroma?3:1, V=chroma?3:1)

grainlayer3 = (g3size==1.0 || sx3==ox && sy3==oy) ? grainlayer3
\           : (g3size > 1.5) ? grainlayer3.bicubicresize(sx3a,sy3a, b3a,c3a).bicubicresize(ox,oy, b3a,c3a)
\                            : grainlayer3.bicubicresize(ox,oy, b3,c3)

#-----------------------------------------------------------------------------------

grainlayer = grainlayer1.mt_merge(grainlayer2,
 \                                 oblr.mt_lut("x "+th1str+" < 0 x "+th2str+" > 255 255 "+th2str+" "+th1str+" - / x "+th1str+" - * ? ?", U=1, V=1),
 \                                 luma=chroma,
 \                                 U=chroma?3:1, V=chroma?3:1)
 \                      .mt_merge(grainlayer3,
 \                                 luma=chroma,
 \                                 oblr.mt_lut("x "+th3str+" < 0 x "+th4str+" > 255 255 "+th4str+" "+th3str+" - / x "+th3str+" - * ? ?", U=1, V=1),
 \                                 U=chroma?3:1, V=chroma?3:1)

grainlayer = (temp_avg==0 || ( g1const==true && g2const==true && g3const==true ) ) ? grainlayer
\          : chroma ? grainlayer.merge(grainlayer.temporalsoften(1,255,255,255,2), tmpavg)
\          :          grainlayer.mergeluma(grainlayer.temporalsoften(1,255,0,255,2), tmpavg)
grainlayer = (  ontop_grain>0  ||  ontop_cgrain>0  ) ? grainlayer.AddGrainC(ontop_grain>0?ontop_grain:0, ontop_cgrain>0?ontop_cgrain:0, 0, 0, constant=ontop_const)
\          : grainLayer
grainLayer = ( ontop_grain<=-1 || ontop_cgrain<=-1 ) ? grainLayer.f3kdb(Y=0, Cb=0, Cr=0, grainY=ontop_grain<=-1?Int(-ontop_grain):0, grainC=ontop_cgrain<=-1?Int(-ontop_cgrain):0, dynamic_grain=!ontop_const, random_algo_grain=1)
\          : grainLayer

#-----------------------------------------------------------------------------------

result = o.mt_makediff(grainlayer, U=ochroma?3:2, V=ochroma?3:2) 

return( result ) }

#-----------------------------------------------------------------------------------
function m4(float x) {return( x<16?16:int(round(x/4.0)*4)) }
#===================================================================================
