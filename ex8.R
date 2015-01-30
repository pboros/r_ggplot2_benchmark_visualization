library(ggplot2)
library(plyr)
library(reshape2)
library(grid)
library(gridExtra)

sysbench_oltp<-read.table("r_ggplot2_benchmark_visualization/sysbench_simple.txt",sep=",",as.is=T,header=F)
colnames(sysbench_oltp)<-c("time","storage","ro_rw","threads","metric","value")

# sysbench_throughput
sysbench_tps<-subset(sysbench_oltp,metric=="sysbench_tps" & threads=="256" & ro_rw=="rw" & storage=='eXFlash DIMM_8')
sysbench_tps$value<-as.numeric(sysbench_tps$value)
sysbench_tps_summ<-ddply(sysbench_tps,c("storage","threads","ro_rw"),
                         summarize,sd_throughput=sd(value),
                         mean_throughput=mean(value),
                         t95th_percentile_throughput=quantile(value, 0.95),
                         max_throughput=max(value))

tps_graph<-ggplot(sysbench_tps)
tps_graph<-tps_graph+aes(x=time,y=value,geom=storage,colour=storage)
tps_graph<-tps_graph+geom_jitter(alpha=0.3)
tps_graph<-tps_graph+expand_limits(y=0)
tps_graph<-tps_graph+theme(legend.position="bottom")
tps_graph<-tps_graph+ylab("Transactions per second")
tps_graph<-tps_graph+guides(colour=guide_legend(override.aes=list(alpha=1, fill=NA)))
tps_graph

ggsave(plot = tps_graph, "r_ggplot2_benchmark_visualization/ex8.png", dpi=200, scale=1, height=6, width=6, type = "cairo-png")
