# Setting up an in-house development HPC cluster

As a high performance computing (HPC) and systems engineering company, we really enjoy
setting up our own hardware clusters. Recently we had an opportunity to purchase
some really good systems off of an IT liquidator company for really cheap. We ended up buying two
[NVIDIA Tesla S1070](http://www.nvidia.in/object/tesla_s1070_in.html) 1U
servers, each with 4 NVIDIA Tesla C1060 GPUs, and 8 [Dell 1950 III](http://www1.la.dell.com/an/en/gen/enterprise/pedge_1950_3/pd.aspx?refid=pedge_1950_3&s=gen) 1U
servers, each with 2 quad-core Xeon 5400 CPUs and 16 GB RAM. The specification
manuals of the NVIDIA system is available [here](http://www.nvidia.com/docs/IO/43395/SP-04154-001_v02.pdf) and for the Dell system is
available
[here](http://www.dell.com/downloads/global/products/pedge/en/pe_1950_III_spec_sheet.pdf).

Despite cloud computing getting more popular, it is definitely useful to have
your own in-house development HPC cluster for doing work. In this blog post, we
explain how we went about setting up an HPC cluster for ourselves. So in all we
were going to have an effective cluster with 64 processing cores and 8 powerful
GPUs. We can use this for prototyping our HPC products, password
cracking using [Hashcat](http://www.hashcat.net), playing with Google's
[Tensorflow](http://www.tensorflow.org) software for deep learning or even
[Litecoin mining](https://litecoin.info/Mining_software). Building your own
cluster can be useful for any purpose.

## Setting up the Rack

We need the following parts in addition to the servers to setup the cluster:

- 1 42U Dell server rack ($250 off of Craigslist)
- 2 1U server rails ($20 each on eBay) for the NVIDIA Tesla S1070
- 8 1U Dell Rails for the Dell 1950 III servers (came with the servers)
- 1 rackmount Power Distribution Unit (PDU). We used [CyberPower
  CPS-1220RMS](https://www.amazon.com/dp/B00077IS32) which has 12 outlets. ($67 on Amazon)
- 1 or 2 2200VA UPS. We used one [CyberPower
  OR2200PFCRT2U](https://www.amazon.com/CyberPower-OR2200PFCRT2Ua-Sinewave-2200VA-Compatible/dp/B003OJAHWA).
($420 on Newegg).
- 4 NVIDIA PCI-e x16 host cards ($25 on eBay)
- 4 Dell-NVIDIA H6GPT Molex PCI-e extension cables for the host PCI-e x16 host
  cards ($35 each on eBay)
- 4 PCI-e x8 to PCI-e x16 Riser cables for attaching the PCI-e x16 host cards to the Dell server's PCI-e
  x8 slots

Each Dell server cost us $85 and each NVIDIA server cost us $165, including
shipping. To connect the NVIDIA servers to the Dell servers, we needed to
purchase 4 PCI-e x16 host cards and cables described above. Except for our
servers and the server rack, every other item was purchased new.

Each NVIDIA server required 110V, 16A input, and the PDU and UPS required 20A
electrical sockets. So we ended up adding two extra 20A electrical lines from the
mains so that they could take the load of the full rack when all the servers
were running at once. This should be enough for our purposes. If we add more
such servers in, we will need to add more 20A lines to handle the load during
100% use of all the servers.

In all, the total cost was about $2100 for complete setup including the
electrical work, which is much cheaper than a single powerful server you could
buy today. But hey, this is a development cluster for ourselves, not for
production use, and setting it up was great fun !

