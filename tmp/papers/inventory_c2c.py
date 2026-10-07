import io,urllib.request,zipfile,pathlib,json
urls=['https://www.ieee802.org/3/ck/public/tools/c2c/gore_3ck_02_0519_PCB.zip','https://www.ieee802.org/3/ck/public/tools/c2c/gore_3ck_03_0519_CA.zip']
class R(io.RawIOBase):
 def __init__(self,url):
  self.url=url;self.pos=0
  with urllib.request.urlopen(urllib.request.Request(url,method='HEAD'),timeout=20) as r:self.size=int(r.headers['Content-Length'])
 def seekable(self):return True
 def tell(self):return self.pos
 def seek(self,o,w=0):self.pos=o if w==0 else self.pos+o if w==1 else self.size+o;return self.pos
 def read(self,n=-1):
  if n<0:n=self.size-self.pos
  if not n:return b''
  with urllib.request.urlopen(urllib.request.Request(self.url,headers={'Range':f'bytes={self.pos}-{self.pos+n-1}'}),timeout=45) as r:
   if r.status!=206:raise RuntimeError('Range not supported')
   d=r.read()
  self.pos+=len(d);return d
for u in urls:
 try:
  obj=R(u);z=zipfile.ZipFile(obj);print(u,obj.size,flush=True);print('\n'.join(z.namelist()),flush=True)
  pathlib.Path('tmp/papers/'+u.split('/')[-1]+'.inventory.json').write_text(json.dumps(z.namelist()))
 except Exception as e:print(type(e).__name__,str(e),flush=True)
