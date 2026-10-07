import io,urllib.request,zipfile,json,pathlib
url='https://www.ieee802.org/3/ck/public/tools/backplane/kareti_3ck_01_1118_backplane.zip'
class Remote(io.RawIOBase):
    def __init__(self): self.pos=0;self.size=187009090
    def seekable(self):return True
    def tell(self):return self.pos
    def seek(self,off,whence=0):
        self.pos=off if whence==0 else self.pos+off if whence==1 else self.size+off
        return self.pos
    def read(self,n=-1):
        if n<0:n=self.size-self.pos
        if not n:return b''
        req=urllib.request.Request(url,headers={'Range':f'bytes={self.pos}-{self.pos+n-1}'})
        with urllib.request.urlopen(req,timeout=45) as r:
            if r.status!=206:raise RuntimeError('Range requests unavailable')
            data=r.read()
        self.pos+=len(data);return data
z=zipfile.ZipFile(Remote())
pathlib.Path('tmp/papers/channel_inventory.json').write_text(json.dumps([{'name':p.filename,'size':p.file_size} for p in z.infolist()],indent=2))
print('\n'.join(z.namelist()))
