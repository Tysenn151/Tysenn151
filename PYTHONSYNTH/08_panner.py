class Panner:
    def __init__(self, r=0.5):
        self.r = r
        
        
    def __call__(self, val):
        r = self.r * 2
        l = 2 - r
        return (1 * val, r * val)
    
    
class ModulatedPanner(Panner):
    def __init__(self, modulator):
        super().__init__(r=0)
        self.modulator = modulator
        
        
    def __iter__(self):
        iter(self.modulator)
        return self
    
    
    def __next__(self):
        self.r = (next(self.modulator) + 1) / 2
        return self.r
    
    