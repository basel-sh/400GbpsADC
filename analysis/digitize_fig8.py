"""Trace published Fig.8 magnitudes; phase cannot be recovered from this figure."""
from pathlib import Path
import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
root=Path(__file__).resolve().parents[1]
im=np.asarray(Image.open(root/'channel/data/fig8/fig8_source.jpeg').convert('RGB')).astype(float)
x0,x1,y0,y1=177,1510,76,681
xs=np.arange(x0+8,x1-3);f=(xs-x0)/(x1-x0)*40
main_pred=np.interp(f,[0,2,5,10,15,20,25,30,35,40],[0,-2.5,-4.5,-7.7,-10,-13,-15,-17.5,-20.5,-22.7])
fext_pred=np.interp(f,[0,1,2,3.7,5,8,10,12,15,20,25,30,35,40],[-46,-39,-35.5,-31.5,-30,-28.5,-29,-27,-26.6,-27,-27.2,-26,-25.5,-27])
traces=[]
for prediction,low,hi in [(main_pred,0,110),(fext_pred,135,225)]:
    yy=[]
    for x,p in zip(xs,prediction):
        center=y0-p*(y1-y0)/50
        lo=max(y0+3,int(center-22));high=min(y1-3,int(center+22))
        rgb=im[lo:high,x,:];gray=rgb.mean(axis=1)
        mask=(gray>=low)&(gray<hi)&(np.ptp(rgb,axis=1)<12)
        candidates=np.where(mask)[0]+lo
        yy.append(float(candidates[np.argmin(abs(candidates-center))]) if len(candidates) else np.nan)
    yy=np.asarray(yy);ok=np.isfinite(yy)
    yy=np.interp(xs,xs[ok],yy[ok]);traces.append(-(yy-y0)/(y1-y0)*50)
dest=root/'channel/data/fig8';dest.mkdir(parents=True,exist_ok=True)
for name,db in zip(['thru','fext'],traces):
    # Include explicit DC endpoint: magnitude-only DC continuation is an assumption.
    dc=0 if name=='thru' else -80
    fq=np.r_[0,f,40]*1e9;mag=np.r_[dc,db,db[-1]]
    np.savetxt(dest/(name+'.csv'),np.column_stack([fq,10**(mag/20),np.zeros_like(fq),mag]),delimiter=',',header='frequency_Hz,real,imag,magnitude_dB',comments='')
fig,ax=plt.subplots(figsize=(10,5));ax.imshow(im.astype('uint8'))
for name,db in zip(['THRU trace','FEXT trace'],traces):ax.plot(xs,y0-db*(y1-y0)/50,lw=1,label=name)
ax.axis('off');ax.legend(loc='upper left');fig.tight_layout();fig.savefig(dest/'trace_review.png',dpi=160)
print('Extracted Figure 8; approximate magnitudes only, no measured phase.')
