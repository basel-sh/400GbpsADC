import io,urllib.request,zipfile
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
  with urllib.request.urlopen(q,timeout=45) as x:d=x.read()
  self.pos+=len(d);return d
z=zipfile.ZipFile(R()); names=[n for n in z.namelist() if '_f' in n.lower() and n.lower().endswith('.s4p')]
print('FEXT s4p count',len(names));print('\n'.join(names[:200]));
