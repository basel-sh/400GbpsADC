import io,urllib.request,zipfile,pathlib,numpy as np,json
url='https://www.ieee802.org/3/ck/public/tools/backplane/kareti_3ck_01_1118_backplane.zip';size=187009090
class R(io.RawIOBase):
 def __init__(self):self.pos=0
 def seekable(self):return True
 def tell(self):return self.pos
 def seek(self,o,w=0):self.pos=o if w==0 else self.pos+o if w==1 else size+o;return self.pos
 def read(self,n=-1):
  if n<0:n=size-self.pos
  if not n:return b''
  q=urllib.request.Request(url,headers={'Range':f'bytes={self.pos}-{self.pos+n-1}'})
  with urllib.request.urlopen(q,timeout=60) as x:d=x.read()
  self.pos+=len(d);return d
out=pathlib.Path('channel/data/ieee_candidates');out.mkdir(parents=True,exist_ok=True)
z=zipfile.ZipFile(R());target=np.loadtxt('channel/data/fig8/fext.csv',delimiter=',',skiprows=1);tf=np.linspace(1e9,37e9,100);rows=[]
for i in range(1,6):
 name=f'Bch2_7_f{i}.s4p';p=out/name
 if not p.exists():p.write_bytes(z.read(name))
 toks=' '.join(l.split('!')[0] for l in p.read_text().splitlines() if not l.startswith(('!','#')))
 a=np.fromstring(toks,sep=' ').reshape(-1,33);f=a[:,0];v=a[:,1:].reshape(-1,16,2);s=(10**(v[:,:,0]/20)*np.exp(1j*np.deg2rad(v[:,:,1]))).reshape(-1,4,4)
 h=(s[:,1,0]-s[:,1,2]-s[:,3,0]+s[:,3,2])/2;db=20*np.log10(np.maximum(abs(h),1e-15));err=float(np.sqrt(np.mean((np.interp(tf,f,db)-np.interp(tf,target[:,0],target[:,3]))**2)))
 rows.append({'file':name,'rmse_dB':err,'loss3p7':float(-np.interp(3.7e9,f,db)),'loss40':float(-np.interp(40e9,f,db))})
 np.savetxt(out/(p.stem+'_sdd21.csv'),np.c_[f,h.real,h.imag,db],delimiter=',',header='frequency_Hz,real,imag,magnitude_dB',comments='')
 print(rows[-1],flush=True)
(out/'Bch2_7_fext_fig8_ranking.json').write_text(json.dumps(rows,indent=2))
