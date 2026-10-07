import io,urllib.request,zipfile,pathlib,numpy as np
exec(open('tmp/papers/list_ieee_fext.py').read().split('z=zipfile.ZipFile(R());')[0])
z=zipfile.ZipFile(R());out=pathlib.Path('channel/data/ieee_candidates')
target=np.loadtxt('channel/data/fig8/fext.csv',delimiter=',',skiprows=1);tf=np.linspace(1e9,37e9,100);m=np.loadtxt('channel/data/ieee_shape_search/Bch2_7_t.csv',delimiter=',',skiprows=1)
for n in ['Bch1_3p5_f1.s4p','Bch3_14_f1.s4p','Bch4_30_f1.s4p']:
 p=out/n
 if not p.exists():p.write_bytes(z.read(n))
 toks=' '.join(l.split('!')[0] for l in p.read_text().splitlines() if not l.startswith(('!','#')));a=np.fromstring(toks,sep=' ').reshape(-1,33);f=a[:,0];v=a[:,1:].reshape(-1,16,2);s=(10**(v[:,:,0]/20)*np.exp(1j*np.deg2rad(v[:,:,1]))).reshape(-1,4,4);h=(s[:,1,0]-s[:,1,2]-s[:,3,0]+s[:,3,2])/2;db=20*np.log10(np.maximum(abs(h),1e-15));np.savetxt(out/(p.stem+'_sdd21.csv'),np.c_[f,h.real,h.imag,db],delimiter=',',header='frequency_Hz,real,imag,magnitude_dB',comments='');fq=75.25e9*50/1024
 print(n,'ratio@3.7',np.interp(fq,m[:,0],m[:,3])-np.interp(fq,f,db),'loss3.7',-np.interp(fq,f,db),'rmse',np.sqrt(np.mean((np.interp(tf,f,db)-np.interp(tf,target[:,0],target[:,3]))**2)),flush=True)
