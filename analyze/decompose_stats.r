#!/usr/bin/env Rscript
library(data.table)

values <- read.csv(file=pipe("cat < /dev/stdin"),head=TRUE,sep=";")
#names(values)

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

short_instance<-sapply(values$instance,instance_name)
dtf <- data.frame(set=values$set,treewidth=values$width,seed=values$seed,decomp_time=values$decomp_time,short=short_instance)
#head(dtf,n=10)
dt <- data.table(dtf)
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

#renaming and col clean
new$short<-sapply(new$short,instance_name_new)
names(new)[names(new)=="min"]<-"min_new"
names(new)[names(new)=="max"]<-"max_new"
names(new)[names(new)=="seed"]<-"seed_new"
names(new)[names(new)=="sd"]<-"sd_new"
names(new)[names(new)=="mean"]<-"mean_new"
new$decomp_time <- NULL
new$set <- NULL
new$treewidth <- NULL
old$treewidth <- NULL
old$decomp_time <- NULL
results<-merge(new,old,by="short")
#results

#save as csv
#write.table(results,file='out.csv')
write.csv(results,file='out.csv')

#order
results<-results[order(results$min_new),]

library(gplots)

pdf('myplot.pdf',width=20)

library(foreach)
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
  barplot2(height=current$mean_new,plot.ci=TRUE,ci.l=current$min_new,ci.u=current$max_new,xlab='instance',ylab='width',col=grays,main=i)
  #axis(1, at=1:200)
  axis(1, at=seq(0, 250, by=25))
  barplot2(height=current$mean,plot.ci=TRUE,ci.l=current$min,ci.u=current$max,xlab='instance',ylab='width',col=grays,main=i)
}

#plot.new()
#plot(results$short,type='p') #,type="1")
#points(results$min_new,col='red')

#plot(c)
dev.off()
