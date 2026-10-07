import numpy as np,pathlib,csv,json
out=pathlib.Path('channel/data/ieee_candidates'); rows=[]
for p in out.glob('*.s4p'):
    tokens=' '.join(l.split('!')[0] for l in p.read_text().splitlines() if not l.startswith(('!','#')))
    a=np.fromstring(tokens,sep=' ').reshape(-1,33); f=a[:,0]; vals=a[:,1:].reshape(-1,16,2)
    s=(10**(vals[:,:,0]/20)*np.exp(1j*np.deg2rad(vals[:,:,1]))).reshape(-1,4,4)
    h=(s[:,1,0]-s[:,1,2]-s[:,3,0]+s[:,3,2])/2
    db=20*np.log10(abs(h)); data=np.column_stack((f,h.real,h.imag,db))
    np.savetxt(out/(p.stem+'_sdd21.csv'),data,delimiter=',',header='frequency_Hz,real,imag,magnitude_dB',comments='')
    rows.append({'file':p.name,'max_GHz':float(f[-1]/1e9),'loss3p7_dB':float(-np.interp(3.7e9,f,db)),'loss40_dB':float(-np.interp(40e9,f,db))})
print(json.dumps(rows,indent=2)); (out/'anchor_comparison.json').write_text(json.dumps(rows,indent=2))
