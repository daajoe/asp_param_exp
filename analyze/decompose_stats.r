#!/usr/bin/env Rscript
library(data.table)
library(foreach)

args<-commandArgs(TRUE)
values <- read.csv(file=args[1],head=TRUE,sep=";")
basic_stats <- read.csv(file=args[2],head=TRUE,sep=";")

instance_name <- function(value){
  str<-unlist(strsplit(toString(value),"/"))
  #return(str[length(str)])
  #let's shorten it 
  str<-gsub(".lparse.bz2","",str[length(str)])
  return(str)
}

instance_name_new <- function(value){
  str<-unlist(gsub(".new","",toString(value)))
  #str<-gsub(".lparse.bz2","",str)
  return(str)
}


#prep basic statistics
short_instance<-sapply(basic_stats$instance,instance_name)
s_dtf <- data.frame(atoms=basic_stats$atoms,rules=basic_stats$rules,bodies=basic_stats$bodies,equiv=basic_stats$equiv,tight=basic_stats$tight,variables=basic_stats$variables,constraints=basic_stats$constraints,short=short_instance)
s_dt <- data.table(s_dtf)

#prep treewidth data
short_instance<-sapply(values$instance,instance_name)
dtf <- data.frame(set=values$set,treewidth=values$width,seed=values$seed,decomp_time=values$decomp_time,short=short_instance)
dt <- data.table(dtf)
#merge stats in
dt<-merge(dt,s_dt,by="short")

#dt[dt$short == '0001-adf_wf-10-8.asp.lparse.bz2']
#obtain sd derivations
resSD<-dt[,list(min=min(treewidth),max=max(treewidth),sd=round(sd(treewidth),digit=2),mean=round(mean(treewidth),digit=2)),by=short]
#resSD<-resSD[order(resSD$short),]
#drop cols
#resSD$min <- NULL
#head(resSD,n=10)

#group by and keep the values
res<-dt[dt[, .I[which.min(treewidth)], by=short]$V1]
#res<-res[order(res$short),]
#merge in sd
res<-merge(res,resSD,by="short")
#order things
res<-res[order(res$min),]
#res<-res[order(res$short),]
new<-res[short %like% 'new']
#old<-res[short %like% 'asp.lparse']
old<-res[short %like% 'asp$']
#head(new)
#head(old)

#remove unnecessary cols
rm_cols <- function(data, cols){
  `%ni%` <- Negate(`%in%`)
  eval.parent(substitute(data<-subset(data,select = names(data) %ni% cols)))
}

rm_cols(new,c("decomp_time","set","treewidth"))
rm_cols(old,c("decomp_time","treewidth"))

#rename cols for later usage
coln = c('a','b','c')

colnames <- function(data,keep){
  rename = names(data)
  #remove keep values
  idx = which(names(data) %in% keep )
  cols=rename[-idx]
  nu_cols<-sapply(cols,function(x) paste(x,"new",sep = "_"))
  return(list(cols,nu_cols))
}


list <- structure(NA,class="result")
"[<-.result" <- function(x,...,value) {
  args <- as.list(match.call())
  args <- args[-c(1:2,length(args))]
  length(value) <- length(args)
  for(i in seq(along=args)) {
    a <- args[[i]]
    if(!missing(a)) eval.parent(substitute(a <- v,list(a=a,v=value[[i]])))
   }
   x
}

list[cols,nu_cols]<-colnames(new,c("short"))
setnames(new,cols,nu_cols)

#merge both encodings
new$short<-sapply(new$short,instance_name_new)
results<-merge(new,old,by="short")

#save as csv
write.csv(results,file='out.csv')

#order
results<-results[order(results$min_new),]

#results$atoms_new
#results$rules_new

#m<-max(results$rules_new)
#m
#exit

cor(results$atoms_new,results$min_new)
cor(results$rules_new,results$min_new)

#plot data
library(gplots)
pdf('myplot.pdf',width=20)
t <- foreach(i=unique(results$set)) %do% {
  current<-results[results$set == i]
  #draw min/max/mean/s
  #pdf("|lp -o landscape", paper = "a4r")
  #dotchart(results$min,labels=results$short)
  #dotchart(results$min,labels=results$short)
  #plot(results$min_new,pch=2,xlab="instance",ylab="width")
  #points(results$max_new,pch=6)
  heights<-current$mean_new
  rel.hts<-(heights - min(heights)) / (max(heights)-min(heights))
  #grays<-gray(1 - rel.hts)
  #grays = c(rep("red",1),rep("blue",1),rep("green",1))
  #grays = c(rep("cadetblue1",1),rep("aquamarine",1))
  grays = c(rep("cadetblue1",1),rep("cadetblue3",1))
  pairs(~current$min_new+rules_new+atoms_new,data=current, main="Matrix: Width & Rules & Atoms")
  barplot2(height=current$mean_new,plot.ci=TRUE,ci.l=current$min_new,ci.u=current$max_new,xlab='instance',ylab='width',col=grays,main=i)
  #plot(current$min_new,pch=2, axes = T,xlab='instance',ylab='width',col=grays)  #17
  par(new = T)
  m<-max(max(current$rules_new),max(current$atoms_new))
  plot(current$rules_new,pch=20, axes = F,xlab='',ylab='',col="black",ylim=c(0,m))
  par(new = T)
  plot(current$atoms_new,pch=4, axes = F,xlab='',ylab='',col="brown3",ylim=c(0,m))
  #axis(side=4, col="brown3",col.axis="brown3",at = pretty(range(results$atoms_new)))
  axis(side=4, col="brown3",col.axis="brown3",at = pretty(range(results$rules_new)))
  mtext("#Atoms",side=4,col="brown3")
  mtext("                         /#Rules",side=4,col="black") 
  #mtext("#Rules",side=4,col="brown3") 
  axis(1, at=seq(0, 250, by=25))
  #c("aquamarineb","red","black")
  legend("topleft",inset=.02,legend=c("Width","#Atoms","#Rules"), text.col="black",pch=c(15,4,20),col=c("aquamarine","red","black"),box.lty=0)
  barplot2(height=current$mean,plot.ci=TRUE,ci.l=current$min,ci.u=current$max,xlab='instance',ylab='width',col=grays,main=i)
}

#plot.new()
#plot(results$short,type='p') #,type="1")
#points(results$min_new,col='red')

#plot(c)
dev.off()
