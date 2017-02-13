#This file tests the GP model with a Student's t likelihood

using Gadfly
using GaussianProcesses

n = 20
X = linspace(-3,3,n)
sigma = 2.0
Y = X + sigma*rand(Distributions.TDist(3),n)

#plot the data
plot(x=X,y=Y,Geom.point)

#build the model
m = MeanZero()
k = Mat(3/2,0.0,0.0)
l = StuTLik(3,0.1)
gp = GPMC{Float64}(X', vec(Y), m, k, l)

#set the priors (need a better interface)
GaussianProcesses.set_priors!(gp.lik,[Distributions.Normal(-2.0,4.0)])
GaussianProcesses.set_priors!(gp.k,[Distributions.Normal(-2.0,4.0),Distributions.Normal(-2.0,4.0)])

optimize!(gp)
xtest = collect(linspace(-4.0,4.0,20));
fmean, fvar = predict(gp,xtest);


plot(layer(x=xtest,y=fmean,ymin=exp(fmean-1.96sqrt(fvar)),ymax=exp(fmean+1.96sqrt(fvar)),Geom.line,Geom.ribbon),layer(x=X,y=Y,Geom.point))

#MCMC
samples = mcmc(gp;mcrange=Klara.BasicMCRange(nsteps=50000, thinning=10, burnin=10000))

plot(y=samples[end,:],Geom.line) #check MCMC mixing


########

#Plot posterior samples
xtest = linspace(minimum(gp.X),maximum(gp.X),50);
ymean = [];
fsamples = [];
for i in 1:size(samples,2)
    GaussianProcesses.set_params!(gp,samples[:,i])
    GaussianProcesses.update_lpost!(gp)
    push!(ymean, predict(gp,xtest,obs=true)[1])
    push!(fsamples,rand(gp,xtest))
end


layers = []
for f in fsamples
    push!(layers, layer(x=xtest,y=f,Geom.line))
end

plot(layers...,Guide.xlabel("X"),Guide.ylabel("f"))

quant = Array(Float64,50,2);
for i in 1:50
    quant[i,:] = quantile(rateSamples[i,:],[0.05,0.95])
end

plot(layer(x=xtest,y=fmean,ymin=quant[:,1],ymax=quant[:,2],Geom.line,Geom.ribbon),layer(x=vec(X),y=Y,Geom.point))

################################
#Predict

layers = []
for ym in ymean
    push!(layers, layer(x=xtest,y=ym,Geom.line))
end

plot(layers...,Guide.xlabel("X"),Guide.ylabel("y"))


plot(layer(x=xtest,y=mean(ymean),Geom.line),
     layer(x=X,y=Y,Geom.point))
