#in matlab:
#x=rand(512,1);
#[s,f,t,p]=spectrogram(x,ones(1,256),128,256,10);
#save
#
#in julia:
#using MAT
#
#matdata=matread("matlab.mat")
#
#for i in ("x", "f", "t", "p")
#  fid=open("spectrogram_$i.txt","w")
#  print(fid,matdata["$i"])
#  close(fid)
#end

using DSP, Base.Test

x0 = vec(readdlm(joinpath(dirname(@__FILE__), "data", "spectrogram_x.txt"),'\t'))
f0 = vec(readdlm(joinpath(dirname(@__FILE__), "data", "spectrogram_f.txt"),'\t'))
t0 = vec(readdlm(joinpath(dirname(@__FILE__), "data", "spectrogram_t.txt"),'\t'))
p0 = readdlm(joinpath(dirname(@__FILE__), "data", "spectrogram_p.txt"),'\t')
spec = spectrogram(x0, 256, 128; fs=10)
p, f, t = power(spec), freq(spec), time(spec)

# with real input matlab outputs a 1-sided PSD
@test_approx_eq p0 p
@test_approx_eq f0 f
@test_approx_eq t0 t

#Matlab: p = pwelch(0:7, [1, 1, 1, 1, 1, 1, 1, 1], 0, 8, 1, 'twosided')
data = 0:7
data0 = Float64[98.0,
                13.656854249492380,
                 4.0,
                 2.343145750507620,
                 2.0,
                 2.343145750507620,
                 4.0,
                13.656854249492380]
@test_approx_eq power(periodogram(data, onesided=false)) data0
@test_approx_eq power(welch_pgram(data, length(data), 0, onesided=false)) data0
@test_approx_eq power(spectrogram(data, length(data), 0, onesided=false)) data0
@test_approx_eq power(periodogram(complex([data], [data]), onesided=false)) data0*2
@test_approx_eq power(welch_pgram(complex([data], [data]), length(data), 0, onesided=false)) data0*2
@test_approx_eq power(spectrogram(complex([data], [data]), length(data), 0, onesided=false)) data0*2

# # ~~~~~~~~ Tests with no window ~~~~~~~~~~~~~~~~~~~
# Matlab: p = pwelch(0:7, [1, 1], 0, 2, 1, 'twosided')
expected = Float64[34.5, 0.5]
@test_approx_eq power(welch_pgram(data, 2, 0; onesided=false)) expected
@test_approx_eq mean(power(spectrogram(data, 2, 0; onesided=false)), 2) expected

# Matlab: p = pwelch(0:7, [1, 1, 1], 0, 3, 1, 'twosided')
expected = Float64[25.5, 1.0, 1.0]
@test_approx_eq power(welch_pgram(data, 3, 0; onesided=false)) expected
@test_approx_eq mean(power(spectrogram(data, 3, 0; onesided=false)), 2) expected

# Matlab: p = pwelch(0:7, [1, 1, 1], 1, 3, 1, 'twosided')
expected = Float64[35.0, 1.0, 1.0]
@test_approx_eq power(welch_pgram(data, 3, 1; onesided=false)) expected
@test_approx_eq mean(power(spectrogram(data, 3, 1; onesided=false)), 2) expected

# Matlab: p = pwelch(0:7, [1, 1, 1, 1], 1, 4, 1, 'twosided')
expected = Float64[45, 2, 1, 2]
@test_approx_eq power(welch_pgram(data, 4, 1; onesided=false)) expected
@test_approx_eq mean(power(spectrogram(data, 4, 1; onesided=false)), 2) expected

# ~~~~~~~~~~~ This one tests periodogram ~~~~~~~~~~~~
# ~ If functionality of the other arguments has been
# ~ tested above, we only test here that the correct
# ~ value of the spectral density is obtained when
# ~ using a window. More tests to be added if needed
#Matlab: p = pwelch(0:7, window_func(8), 0, 8, 1, 'twosided')
cases = (
    (hamming,  Float64[65.461623986801527,
                       20.556791795515764,
                        0.369313143650544,
                        0.022167446610882,
                        0.025502985564107,
                        0.022167446610882,
                        0.369313143650544,
                       20.556791795515764]),
    (bartlett, Float64[62.999999999999993,
                       21.981076052592442,
                        0.285714285714286,
                        0.161781090264695,
                        0.142857142857143,
                        0.161781090264695,
                        0.285714285714286,
                       21.981076052592442])
)

for (window1, expected) in cases
    @test_approx_eq power(periodogram(data; window=window1, onesided=false)) expected
    @test_approx_eq power(welch_pgram(data, length(data), 0; window=window1, onesided=false)) expected
    @test_approx_eq power(spectrogram(data, length(data), 0; window=window1, onesided=false)) expected
    @test_approx_eq power(periodogram(data; window=window1(length(data)), onesided=false)) expected
    @test_approx_eq power(welch_pgram(data, length(data), 0; window=window1(length(data)), onesided=false)) expected
    @test_approx_eq power(spectrogram(data, length(data), 0; window=window1(length(data)), onesided=false)) expected
end

# Padded periodogram
# MATLAB: a = periodogram(0:7, [], 32);
expected = [
                  98
    174.463067389405
    121.968086934209
    65.4971744936088
    27.3137084989848
    12.1737815028909
    10.3755170959439
    10.4034038628775
                   8
    5.25810953219633
    4.47015397150535
    4.89522578856669
    4.68629150101524
    3.69370284475603
     3.1862419983415
    3.61553458569862
                   2
]
@test_approx_eq power(periodogram(data; nfft=32)) expected
@test_approx_eq power(welch_pgram(data, length(data), 0; nfft=32)) expected
@test_approx_eq power(spectrogram(data, length(data), 0; nfft=32)) expected

# Padded periodogram with window
# MATLAB: a = periodogram(0:7, hamming(8), 32, 1)
expected = [
      65.4616239868015
      122.101693164395
      98.8444689598445
       69.020252632913
      41.1135835910315
      20.5496474310966
      8.43291449161938
      2.78001620362588
     0.738626287301088
     0.174995741770789
    0.0501563022944516
    0.0327357460012861
    0.0443348932217643
    0.0553999745503552
    0.0561319901616643
    0.0526025934871384
    0.0255029855641069
]
@test_approx_eq power(periodogram(data; window=hamming, nfft=32)) expected
@test_approx_eq power(welch_pgram(data, length(data), 0; window=hamming, nfft=32)) expected
@test_approx_eq power(spectrogram(data, length(data), 0; window=hamming, nfft=32)) expected

# Test fftshift
p = periodogram(data)
@test power(p) == power(fftshift(p))
@test_approx_eq freq(p) freq(fftshift(p))

p = periodogram(data; onesided=false)
@test fftshift(power(p)) == power(fftshift(p))
@test fftshift(freq(p)) == freq(fftshift(p))

data = 1:100

p = spectrogram(data)
@test power(p) == power(fftshift(p))
@test_approx_eq freq(p) freq(fftshift(p))

p = spectrogram(data; onesided=false)
@test fftshift(power(p), 1) == power(fftshift(p))
@test fftshift(freq(p)) == freq(fftshift(p))


data2d = readdlm(joinpath(dirname(@__FILE__), "data", "per2dx.txt"),'\t')
expectedsum = vec(readdlm(joinpath(dirname(@__FILE__), "data", "per2dsum.txt"),'\t'))
expectedmean = vec(readdlm(joinpath(dirname(@__FILE__), "data", "per2dmean.txt"),'\t'))
# 2-d periodgram (radialsum)
# computed in octave with raPsd2d ((C) E. Ruzanski) replacing nanmean with nansum
# P = raPsd2d(x,1)'*n^2
@test_approx_eq power(periodogram(data2d,fs=1, radialsum=true)) expectedsum

# 2-d periodgram (radialavg)
# computed in octave with raPsd2d ((C) E. Ruzanski)
# P = raPsd2d(x,1)'*n^2
@test_approx_eq power(periodogram(data2d, fs=1, radialavg=true)) expectedmean

# 2-d periodgram 2-d PSD
@test_approx_eq power(periodogram(data2d, fs=1)) abs2(fft(data2d))*1/prod(size(data2d))
# 2-d periodgram 2-d PSD with padding
pads = (size(data2d,1)+4,size(data2d,1)+7)
data2dpad = zeros(Float64,pads...)
data2dpad[1:size(data2d,1),1:size(data2d,2)] = data2d
@test_approx_eq power(periodogram(data2d, fs=1, nfft=pads)) abs2(fft(data2dpad))*1/prod(size(data2d))
# 2-d periodgram radial freq
@test_approx_eq freq(periodogram(data2d, fs=3.3, radialsum=true)) freq(periodogram(vec(data2d[1,:]), fs=3.3))
# 2-d periodgram 2-d freq
f1,f2 = freq(periodogram(data2d, fs=3.3))
f1d = freq(periodogram(vec(data2d[1,:]), fs=3.3, onesided=false))
@assert size(data2d,1)==size(data2d,2)
for j=1:size(data2d,2)
    for i=1:size(data2d,1)
        @test_approx_eq [f1[i],f2[j]] [f1d[i],f1d[j]]
    end
end
# Test fftshift
p = periodogram(data2d)
@test fftshift(power(p)) == power(fftshift(p))
f = freq(p)
@test (fftshift(f[1]),fftshift(f[2])) == freq(fftshift(p))


# 2-d periodgram radial test for a non-square signal sparse in fft space
n1 = 52
n2 = 46  # assuming n1>n2
nf = (22,7) # the non-zero location
F = (fftfreq(n1,1),fftfreq(n2,1))
a = [F[1][nf[1]],F[2][nf[2]]]
FB = Array(Bool,n1,n2)
for j = 1:n2
    for i = 1:n1
        FB[i,j] = [F[1][i], F[2][j]]==a || [F[1][i], F[2][j]]==-a
    end
end

ind = find(FB)
x = zeros(n1,n2)*0im;
x[ind] = [1+2im,1-2im]
y = real(ifft(x))

fwn = int(sqrt((a[1])^2+(a[2])^2)*n2)
pe = zeros(n2>>1 + 1)
pe[fwn+1] = 2*abs2(x[nf...])/n1/n2
P = periodogram(y,nfft=(n1,n2),radialsum=true)
@test_approx_eq power(P) pe
@test_approx_eq freq(P)[fwn+1] fwn/n2

# Testing STFT function and comparing results with MATLAB

fs = 16000
nfft = 512
nwin = int(0.025*fs)
nhop = int(0.010*fs)
s = vec(readdlm(joinpath(dirname(@__FILE__), "data", "stft_x.txt"),'\t'))

Sjl = stft(s, nwin, nwin-nhop; nfft=nfft, fs=fs, window=hanning)
Sml_re = readdlm(joinpath(dirname(@__FILE__), "data", "stft_S_real.txt"),'\t')
Sml_im = readdlm(joinpath(dirname(@__FILE__), "data", "stft_S_imag.txt"),'\t')
Sml = complex(Sml_re, Sml_im)
@test_approx_eq Sjl Sml

# fft2oneortwosided!
n = 10
floatt = Float64
for onesided in (true, false),
        nfft in (n, n+2, n+3),
       atype in (floatt, Complex{floatt})
    nout = nout = onesided ? (nfft >> 1)+1 : nfft
    x = zeros(atype, nfft)
    if atype <: Real
        x[1:n] = rand(atype, n)
        xrcfft = rfft(x)
    else
        x[1:n] = rand(floatt, n)+im*rand(floatt, n)
        xrcfft = fft(x)
    end
    xfft = fft(x)
    out = zeros(fftouttype(atype),nout,3)
    if !(onesided == true && atype <: Complex)
        outft = DSP.Periodograms.fft2oneortwosided!(out, xrcfft, nfft, onesided, nout)
    end
    if onesided == true && atype <: Real
        @test_approx_eq out[:,2] xrcfft
        @test_approx_eq out[:,[1,3]] xrcfft*[0 0]
    elseif onesided == false && atype <: Real
        @test_approx_eq out[:,2] xfft
        @test_approx_eq out[:,[1,3]] xfft*[0 0]
    elseif onesided == false && atype <: Complex
        @test_approx_eq out[:,2] xfft
        @test_approx_eq out[:,[1,3]] xfft*[0 0]
    else
        #onesided complex
    end
end

# Testing mt_pgram
# MATLAB: x = pmtm(stft_x, 4, 5000, 16000, 'unity')
mtdata = vec(readdlm(joinpath(dirname(@__FILE__), "data", "mt_pgram.txt")))
@test_approx_eq power(mt_pgram(s; fs=16000)) mtdata
@test_approx_eq power(mt_pgram(s; fs=16000, window=dpss(length(s), 4))) mtdata

# error tests
EE = ErrorException
@test_throws EE periodogram([1 2 3])
@test_throws EE periodogram(rand(2,3), nfft=(3,2))
@test_throws EE periodogram([1 2;3 4],radialsum=true, radialavg=true)
