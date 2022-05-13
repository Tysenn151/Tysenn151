from turtle import shape
import numpy as np
import scipy.io.wavfile as wav



def interpolate_linearly(wave_table, index):
    #find the integers nearest to the index
    truncated_index = int(np.floor(index))
    next_index = (truncated_index + 1) % wave_table.shape[0]
    
    next_index_weight = index - truncated_index
    truncated_index_weight = 1 - next_index_weight
    
    return truncated_index_weight * wave_table[truncated_index] + next_index_weight * wave_table[next_index]

def fade_in_out(signal, fade_length=2000):
    # use a fade in fade out envelope.  we'll use 1/2 cosine
    # we need the length of the fade, it's defaulted to 1000 samples (of our 44,100 sample rate)
    fade_in = (1 - np.cos(np.linspace(0, np.pi, fade_length))) * 0.5
    fade_out = np.flip(fade_in)
    
    signal[:fade_length] = np.multiply(fade_in, signal[:fade_length])
    
    signal[-fade_length:] = np.multiply(fade_out, signal[-fade_length:])
    
    return signal

def sawtooth(x):
    return (x + np.pi) / np.pi % 2 - 1
    
def main():
    #parameters we'll use for processing
    sample_rate = 44100 #Sample Rate: 44,100 samples per second
    f = 220 #440             #Frequency: generate a waveform at 440hz for sine, 220 for sawtooth
    t = 3               #Time: it will play for 3 seconds
    #waveform = np.sin   #Waveform: using a sine wave form (shape is from numpy)
    
    #for sawtooth, uses sawtooth function as the waveform
    waveform = sawtooth(1.0)
    
    #The basis for this type of synthesis is the WAVETABLE
    #We need to define this item
    wavetable_length = 64       #
    wave_table = np.zeros((wavetable_length,))
    
    for n in range(wavetable_length):
        wave_table[n] = waveform(2 * np.pi * n / wavetable_length)
        
    output = np.zeros((t * sample_rate,))
    
    
    index = 0
    index_increment = f * wavetable_length / sample_rate
    
    for n in range(output.shape[0]):
        # original, used for _01 and _02
        #output[n] = wave_table[int(np.floor(index))]
        
        #now for _03 ... linear interpolation (8:55)
        output[n] = interpolate_linearly(wave_table, index)
        
        index += index_increment
        index %= wavetable_length
    
    
    gain = -20
    amplitude = 10 ** (gain / 20)
    output *= amplitude
    
    output = fade_in_out(output)
        
    #wav.write('sine440Hz_04_scaledIterpolatedFaded.wav', sample_rate, output.astype(np.float32))
    wav.write('saw220Hz_01_scaledIterpolatedFaded.wav', sample_rate, output.astype(np.float32))



if __name__ == '__main__':
    main()
    
    
    

