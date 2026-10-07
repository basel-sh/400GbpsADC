"""Parse four-port Touchstone DB/RI/MA and compare magnitudes with Fig.8."""
import pathlib,json,numpy as np
root=pathlib.Path(__file__).resolve().parents[1]
def parse(p):
 lines=p.read_text().splitlines();opts=next(l for l in lines if l.lstrip().startswith('#')).upper().split()
 unit=opts[1];fmt=opts[3];factor={'HZ':1,'KHZ':1e3,'MHZ':1e6,'GHZ':1e9}[unit]
 tokens=' '.join(l.split('!')[0] for l in lines if not l.lstrip().startswith(('!','#')))
 a=np.fromstring(tokens,sep=' ').reshape(-1,33);f=a[:,0]*factor;v=a[:,1:].reshape(-1,16,2)
 if fmt=='RI':z=v[:,:,0]+1j*v[:,:,1]
 else:z=(10**(v[:,:,0]/20) if fmt=='DB' else v[:,:,0])*np.exp(1j*np.deg2rad(v[:,:,1]))
 s=z.reshape(-1,4,4);h=(s[:,1,0]-s[:,1,2]-s[:,3,0]+s[:,3,2])/2
 return f,h
if __name__=='__main__':
 rows=[]
 for folder in ['c2c_candidates','ieee_shape_search']:
  dest=root/'channel/data'/folder
  for p in dest.glob('*.s4p'):
   f,h=parse(p);db=20*np.log10(abs(h));kind='fext' if 'fext' in p.stem else 'thru'
   target=np.loadtxt(root/'channel/data/fig8'/f'{kind}.csv',delimiter=',',skiprows=1)
   tf=np.linspace(1e9,min(37e9,f[-1]),100)
   err=np.sqrt(np.mean((np.interp(tf,f,db)-np.interp(tf,target[:,0],target[:,3]))**2))
   np.savetxt(dest/(p.stem+'.csv'),np.column_stack([f,h.real,h.imag,db]),delimiter=',',header='frequency_Hz,real,imag,magnitude_dB',comments='')
   rows.append({'file':str(p.relative_to(root)),'kind':kind,'curve_RMSE_dB':float(err), 'max_GHz':float(f[-1]/1e9), 'loss3p7_dB':float(-np.interp(3.7e9,f,db)), 'loss40_dB':float(-np.interp(40e9,f,db))})
 rows.sort(key=lambda r:(r['kind'],r['curve_RMSE_dB']));(root/'results/target_reproduction/channel_ranking.json').write_text(json.dumps(rows,indent=2));print(json.dumps(rows[:12],indent=2))
