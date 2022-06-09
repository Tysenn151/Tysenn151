from numpy import isin


from collections.abc import Iterable

class Volume:
    
    def __init__(self, amp = 1.):
        self.amp = amp
    
    def __call__(self,val):
        _val = None
        if isinstance(val, Iterable):
            _val = tuple(v * self.amp for v in val)
        elif isinstance(val, (int, float)):
            _val = val * self.amp
            
        return _val
    
class ModulatedVolume(Volume):
    def __init__(self, modulator):
        super().__init__(0.)
        self.modulator = modulator
        
        
    def __iter__(self):
        iter(self.modulator)
        return self
    
    
    def __next__(self):
        self.amp = next(self.modulator)
        return self.amp
    
    
    def trigger_release(self):
        if hasattr(self.modulator, "trigger_release"):
            self.modulator.trigger_release()
            
            
            
    @property
    def ended(self):
        ended = False
        if hasattr(self.modulator, "ended"):
            ended = self.modulator.ended
            
        return ended
    