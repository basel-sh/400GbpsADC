"""Search the cited IEEE traditional backplane data by Figure 8 shape, not BER."""
import io, urllib.request, zipfile, pathlib, concurrent.futures, json, numpy as np
root=pathlib.Path(__file__).resolve().parents[1]
url='https://www.ieee802.org/3/ck/public/tools/backplane/kareti_3ck_01_1118_backplane.zip'
size=187009090
class Remote(io.RawIOBase):
 def __init__(self):self.pos=0
 def seekable(self):return True
 def tell(self):return self.pos
 def seek(self,o,w=0):
  self.pos=o if w==0 else self.pos+o if w==1 else size+o
  return self.pos
 def read(self,n=-1):
  if n<0:n=size-self.pos
  if not n:return b''
  req=urllib.request.Request(url,headers={'Range':f'bytes={self.pos}-{self.pos+n-1}'})
  with urllib.request.urlopen(req,timeout=45) as r:
   if r.status!=206:raise RuntimeError('Range requests unavailable')
   d=r.read()
  self.pos+=len(d);return d
dest=root/'channel/data/ieee_shape_search';dest.mkdir(parents=True,exist_ok=True)
names=[n for n in zipfile.ZipFile(Remote()).namelist() if n.endswith('_t.s4p')]
target=np.loadtxt(root/'channel/data/fig8/thru.csv',delimiter=',',skiprows=1)
tf=np.linspace(1e9,37e9,100)
def work(name):
 p=dest/name
 if not p.exists():p.write_bytes(zipfile.ZipFile(Remote()).read(name))
 tokens=' '.join(l.split('!')[0] for l in p.read_text().splitlines() if not l.startswith(('!','#')))
 a=np.fromstring(tokens,sep=' ').reshape(-1,33);f=a[:,0];v=a[:,1:].reshape(-1,16,2)
 s=(10**(v[:,:,0]/20)*np.exp(1j*np.deg2rad(v[:,:,1]))).reshape(-1,4,4)
 h=(s[:,1,0]-s[:,1,2]-s[:,3,0]+s[:,3,2])/2;db=20*np.log10(abs(h))
 err=np.sqrt(np.mean((np.interp(tf,f,db)-np.interp(tf,target[:,0],target[:,3]))**2))
 np.savetxt(dest/(p.stem+'.csv'),np.column_stack([f,h.real,h.imag,db]),delimiter=',',header='frequency_Hz,real,imag,magnitude_dB',comments='')
 return {'file':name,'curve_RMSE_dB':float(err),'loss40_dB':float(-np.interp(40e9,f,db))}
rows=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
 for future in concurrent.futures.as_completed({ex.submit(work,n):n for n in names}):
  try:r=future.result();rows.append(r);print(r,flush=True)
  except Exception as e:print('FAILED',str(e),flush=True)
rows.sort(key=lambda r:r['curve_RMSE_dB']);(dest/'shape_ranking.json').write_text(json.dumps(rows,indent=2))
print('SEARCH_COMPLETE',rows[:3])
