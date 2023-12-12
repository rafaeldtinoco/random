#include "conntracker.h"
#include "general.h"
#include "flows.h"
#include "footprint.h"
#include "nlmsg.h"
#include "iptables.h"
#include "bpftracker.h"

GMainLoop *loop;

int logfd;
char *logfile;
int amiadaemon;
int tracefeat;
int traceitall;
int ebpfenable;

GSequence *tcpv4flows;
GSequence *udpv4flows;
GSequence *icmpv4flows;
GSequence *tcpv6flows;
GSequence *udpv6flows;
GSequence *icmpv6flows;

gint ulognlctiocbio_event_cb(const struct nlmsghdr *nlh, void *data)
{
	int ret;
	const char *prefix = NULL;

	struct nfgenmsg *nfg;
	struct nlattr *attrs[NFULA_MAX + 1] = { NULL };

	struct nf_conntrack *ct = NULL;
	struct footprint fp;

	// raw netlink msgs related to ulog (trace match)

	ret = nflog_nlmsg_parse(nlh, attrs);

	if (ret != MNL_CB_OK)
		EXITERR("nflog_nlmsg_parse");

	nfg = mnl_nlmsg_get_payload(nlh);

	if (!attrs[NFULA_PREFIX])
		return MNL_CB_OK;

	prefix = mnl_attr_get_str(attrs[NFULA_PREFIX]);

	if (!prefix)
		EXITERR("mnl_attr_get_str");

	if (strlen(prefix) == 0)
		return MNL_CB_OK;

	if (!attrs[NFULA_CT])
		return MNL_CB_OK;

	/*
	 * when receiving ulog netlink msgs from kernel (for TRACE) we have:
	 *
	 * TRACE: table:chain:type:position
	 *        [0]   [1]   [2]  [3]
	 */

	gchar **vector = g_strsplit_set((prefix+strlen("TRACE: ")), ":", -1);

	memset(&fp, 0, sizeof(struct footprint));

	// chain name

	g_strlcpy(fp.chain, vector[1], strlen(vector[1])+1);

	// table name

	if (g_ascii_strcasecmp("raw", vector[0]) == 0)
		fp.table = FOOTPRINT_TABLE_RAW;
	if (g_ascii_strcasecmp("mangle", vector[0]) == 0)
		fp.table = FOOTPRINT_TABLE_MANGLE;
	if (g_ascii_strcasecmp("nat", vector[0]) == 0)
		fp.table = FOOTPRINT_TABLE_NAT;
	if (g_ascii_strcasecmp("filter", vector[0]) == 0)
		fp.table = FOOTPRINT_TABLE_FILTER;
	if (fp.table == 0)
		fp.table = FOOTPRINT_TABLE_UNKNOWN;

	// rule type

	if (g_ascii_strcasecmp("policy", vector[2]) == 0)
		fp.type = FOOTPRINT_TYPE_POLICY;
	if (g_ascii_strcasecmp("rule", vector[2]) == 0)
		fp.type = FOOTPRINT_TYPE_RULE;
	if (g_ascii_strcasecmp("return", vector[2]) == 0)
		fp.type = FOOTPRINT_TYPE_RETURN;
	if (fp.type == 0)
		fp.type = FOOTPRINT_TYPE_UNKNOWN;

	// position of the rule (# is always shifted 1 because of conntracker rules)

	fp.position = (uint32_t) ((long int) strtol(vector[3], NULL, 0));

	// no need for vector

	g_strfreev(vector);

	// conntrack data related, extracted from the netlink communication

	ct = nfct_new();
	if (!ct)
		EXITERR("nfct_new");

	if (nfct_payload_parse(mnl_attr_get_payload(attrs[NFULA_CT]),
			       mnl_attr_get_payload_len(attrs[NFULA_CT]),
			       nfg->nfgen_family, ct) < 0)
		EXITERR("nfct_payload_parse");

	/*
	 * ready to call conntracio_event_cb (like) function to populate
	 * in-memory trees note: different than when calling from
	 * libnetfilter_conntrack path, this one includes the tracing data with
	 * a pointer to a local footprint struct (that shall be copied in the
	 * conntrackio_event_cb and kept in memory with the flow list items
	 */

	ret = conntrackio_event_cb(NF_NETLINK_CONNTRACK_UPDATE, ct, &fp);

	nfct_destroy(ct);

	return MNL_CB_OK;
}

gint conntrackio_event_cb(enum nf_conntrack_msg_type type, struct nf_conntrack *ct, void *data)
{
	u8 reply = 0;
	u8 family, proto;
	u8 itype, icode;
	u16 sport, dport, rsport, rdport;
	u32 constatus;
	struct in_addr ip4src, ip4dst, ip4rsrc, ip4rdst;
	struct in6_addr ip6src, ip6dst, ip6rsrc, ip6rdst;

	struct footprint *fp = data;

	memset(&ip4src, 0, sizeof(struct in_addr)); memset(&ip4dst, 0, sizeof(struct in_addr));
	memset(&ip4rsrc, 0, sizeof(struct in_addr)); memset(&ip4rdst, 0, sizeof(struct in_addr));
	memset(&ip6src, 0, sizeof(struct in6_addr)); memset(&ip6dst, 0, sizeof(struct in6_addr));
	memset(&ip6rsrc, 0, sizeof(struct in6_addr)); memset(&ip6rdst, 0, sizeof(struct in6_addr));

	constatus = *((u32 *) nfct_get_attr(ct, ATTR_STATUS));
	if (constatus & IPS_SEEN_REPLY)
		reply = 1;

	family = *((u8 *) nfct_get_attr(ct, ATTR_L3PROTO));
	switch (family) {
	case AF_INET:
	case AF_INET6:
		break;
	default:
		return NFCT_CB_CONTINUE;
	}

	proto = *((u8 *) nfct_get_attr(ct, ATTR_L4PROTO));
	switch (proto) {
	case IPPROTO_TCP:
	case IPPROTO_UDP:
	case IPPROTO_ICMP:
	case IPPROTO_ICMPV6:
		break;
	default:
		return NFCT_CB_CONTINUE;
	}

	switch (family) {
	case AF_INET:
		ip4src.s_addr = *((in_addr_t *) nfct_get_attr(ct, ATTR_IPV4_SRC));
		ip4dst.s_addr = *((in_addr_t *) nfct_get_attr(ct, ATTR_IPV4_DST));
		ip4rsrc.s_addr = *((in_addr_t *) nfct_get_attr(ct, ATTR_REPL_IPV4_SRC));
		ip4rdst.s_addr = *((in_addr_t *) nfct_get_attr(ct, ATTR_REPL_IPV4_DST));
		break;
	case AF_INET6:
		memcpy(&ip6src, nfct_get_attr(ct, ATTR_IPV6_SRC), sizeof(struct in6_addr));
		memcpy(&ip6dst, nfct_get_attr(ct, ATTR_IPV6_DST), sizeof(struct in6_addr));
		memcpy(&ip6rsrc, nfct_get_attr(ct, ATTR_REPL_IPV6_SRC), sizeof(struct in6_addr));
		memcpy(&ip6rdst, nfct_get_attr(ct, ATTR_REPL_IPV6_DST), sizeof(struct in6_addr));
		break;
	}

	switch (proto) {
	case IPPROTO_TCP:
	case IPPROTO_UDP:
		sport = *((u16 *) nfct_get_attr(ct, ATTR_PORT_SRC));
		dport = *((u16 *) nfct_get_attr(ct, ATTR_PORT_DST));
		rsport = *((u16 *) nfct_get_attr(ct, ATTR_REPL_PORT_SRC));
		rdport = *((u16 *) nfct_get_attr(ct, ATTR_REPL_PORT_DST));
		break;
	case IPPROTO_ICMP:
	case IPPROTO_ICMPV6:
		itype = *((u8 *) nfct_get_attr(ct, ATTR_ICMP_TYPE));
		icode = *((u8 *) nfct_get_attr(ct, ATTR_ICMP_CODE));
		break;
	}

	switch (family) {
	case AF_INET:
		switch (proto) {
		case IPPROTO_TCP:
			add_tcpv4flow(ip4src, ip4dst, sport, dport);
			if (fp != NULL)
				add_tcpv4fp(ip4src, ip4dst, sport, dport, fp);
			else
				if (tracefeat)
					start_tcpv4trace(ip4src, ip4dst, sport, dport);
			if (!reply)
				break;
			add_tcpv4flow(ip4rsrc, ip4rdst, rsport, rdport);
			if (fp != NULL)
				add_tcpv4fp(ip4rsrc, ip4rdst, rsport, rdport, fp);
			else
				if (tracefeat)
					start_tcpv4trace(ip4rsrc, ip4rdst, rsport, rdport);
			break;
		case IPPROTO_UDP:
			add_udpv4flow(ip4src, ip4dst, sport, dport);
			if (fp != NULL)
				add_udpv4fp(ip4src, ip4dst, sport, dport, fp);
			else
				if (tracefeat)
					start_udpv4trace(ip4src, ip4dst, sport, dport);
			if (!reply)
				break;
			add_udpv4flow(ip4rsrc, ip4rdst, rsport, rdport);
			if (fp != NULL)
				add_udpv4fp(ip4rsrc, ip4rdst, rsport, rdport, fp);
			else
				if (tracefeat)
					start_udpv4trace(ip4rsrc, ip4rdst, rsport, rdport);
			break;
		case IPPROTO_ICMP:
			add_icmpv4flow(ip4src, ip4dst, itype, icode);
			if (fp != NULL)
				add_icmpv4fp(ip4src, ip4dst, itype, icode, fp);
			else
				if (tracefeat)
					start_icmpv4trace(ip4src, ip4dst, itype, icode);
			break;
		}
		break;
	case AF_INET6:
		switch (proto) {
		case IPPROTO_TCP:
			add_tcpv6flow(ip6src, ip6dst, sport, dport);
			if (fp != NULL)
				add_tcpv6fp(ip6src, ip6dst, sport, dport, fp);
			else
				if (tracefeat)
					start_tcpv6trace(ip6src, ip6dst, sport, dport);
			if (!reply)
				break;
			add_tcpv6flow(ip6rsrc, ip6rdst, rsport, rdport);
			if (fp != NULL)
				add_tcpv6fp(ip6rsrc, ip6rdst, rsport, rdport, fp);
			else
				if (tracefeat)
					start_tcpv6trace(ip6rsrc, ip6rdst, rsport, rdport);
			break;
		case IPPROTO_UDP:
			add_udpv6flow(ip6src, ip6dst, sport, dport);
			if (fp != NULL)
				add_udpv6fp(ip6src, ip6dst, sport, dport, fp);
			else
				if (tracefeat)
					start_udpv6trace(ip6src, ip6dst, sport, dport);
			if (!reply)
				break;
			add_udpv6flow(ip6rsrc, ip6rdst, rsport, rdport);
			if (fp != NULL)
				add_udpv6fp(ip6rsrc, ip6rdst, rsport, rdport, fp);
			else
				if (tracefeat)
				start_udpv6trace(ip6rsrc, ip6rdst, rsport, rdport);
			break;
		case IPPROTO_ICMPV6:
			add_icmpv6flow(ip6src, ip6dst, itype, icode);
			if (fp != NULL)
				add_icmpv6fp(ip6src, ip6dst, itype, icode, fp);
			else
				if (tracefeat)
					start_icmpv6trace(ip6src, ip6dst, itype, icode);
			break;
		}
		break;
	}
	return NFCT_CB_CONTINUE;
}

void trap(int what)
{
	bpftracker_cleanup();
	cleanup();
	exit(0);
}

gboolean ulognlctiocb(GIOChannel *source, GIOCondition condition, gpointer data)
{
	// deal with ulog (+ conntrack) netfilter netlink messages

	gint ret;
	struct mnl_socket *ulognl = data;
	guint portid = mnl_socket_get_portid(ulognl);
	unsigned char buf[MNL_SOCKET_BUFFER_SIZE] __attribute__ ((aligned));

	ret = mnl_socket_recvfrom(ulognl, buf, sizeof(buf));
	if (ret < 0) {
		ret = mnl_socket_recvfrom(ulognl, buf, sizeof(buf)); // try again
		if (ret < 0)
			EXITERR("mnl_socket_recvfrom"); // give up
	}

	ret = mnl_cb_run(buf, ret, 0, portid, ulognlctiocbio_event_cb, NULL);
	if (ret < 0)
		EXITERR("mnl_cb_run");
	return TRUE; // return FALSE to stop event
}

gboolean conntrackiocb(GIOChannel *source, GIOCondition condition, gpointer data)
{
	/*
	 * deal with conntrack netlink messages by using glib main loop
	 * instead of nfct_catch() approach from libnetfilter-conntrack
	 */

	gint ret;
	struct nfnl_handle *nfnlh = data;
	unsigned char buf[nfnlh->rcv_buffer_size] __attribute__ ((aligned));

	ret = nfnl_recv(nfnlh, buf, sizeof(buf));

	if (ret < 0 && errno != EINTR && errno != 105)
		PERROR("nfnl_recv");

	if (ret < 0 && errno == 105) {
		WARN("too many conntrack nl msgs, might lose some");
		return TRUE;
	}

	ret = nfnl_process(nfnlh, buf, ret);

	if (ret <= NFNL_CB_STOP)
		PERROR("nfnl_process");

	return TRUE; // return FALSE to stop event
}

int usage(int argc, char **argv)
{
	g_fprintf(stdout,
		"\n"
		"Syntax: %s [options]\n"
		"\n"
		"\t[options]:\n"
		"\n"
		"\t-d: daemon mode        (syslog msgs, output file, kill pidfile)\n"
		"\t-f: foreground mode    (stdout msgs, output file, ctrl+c, default)\n"
		"\n"
		"\t-t: trace mode         (trace packets being tracked netfilter)\n"
		"\t-e: trace everything   (trace ALL packets passing through netfilter)\n"
		"\t-b: enable eBPF        (eBPF to catch TCP & UDP flows and their cmds)\n"
		"\n"
		"\t-o: -o file.out        (output file, default: /tmp/conntracker.log)\n"
		"\t    -o -               (standard output)\n"
		"\n"
		"\t1) defaults (no options):\n"
		"\n"
		"\t   a) ONLY packets from ALLOWED rules are tracked.\n"
		"\t   b) IPs, ports and protocols (flows) ARE LOGGED.\n"
		"\t   c) packets from DROPPED/REJECTED rules are NOT logged!\n"
		"\n"
		"\t2) -t (trace mode):\n"
		"\n"
		"\t   a) ONLY packets from ALLOWED rules are tracked.\n"
		"\t   b) IPs, ports and protocols (flows) ARE LOGGED.\n"
		"\t   c) packets from DROPPED/REJECTED rules are NOT logged!\n"
		"\t   d) each flow MIGHT show chains it has passed through (traces).\n"
		"\n"
		"\t3) -e (trace everything):\n"
		"\n"
		"\t   a) ONLY packets from ALLOWED rules are tracked.\n"
		"\t   b) IPs, ports and protocols (flows) ARE LOGGED.\n"
		"\t   c) -\n"
		"\t   d) each flow MIGHT show chains it has passed through (traces).\n"
		"\t   e) packets from DROPPED/REJECTED rules ARE logged!\n"
		"\t   f) WILL ALLOW tracking flows rejected by REJECT rules in place!\n"
		"\t   g) only works with -t (trace mode) enabled.\n"
		"\n"
		"\t3) -b (enable eBPF):\n"
		"\n"
		"\t   h) flows MIGHT show cmdline/pid/user responsible for them\n"
		"\n"
		"\tNote: -e option is recommended if REJECT/DROP rules are in place\n"
		"\n"
		"Check https://rafaeldtinoco.github.io/conntracker/ for more info!\n"
		"Check https://rafaeldtinoco.github.io/portablebpf/ for more info!\n"
		"\n",
		argv[0]);

	exit(0);
}

int main(int argc, char **argv)
{
	int opt, ret = 0;
	int bpftrackertime = 10;
	gchar *outfile = NULL;

	GIOChannel *conntrackio = NULL;
	GIOChannel *ulognlctio = NULL;

	struct nfct_handle *nfcth = NULL;
	struct nfnl_handle *nfnlh = NULL;
	struct mnl_socket *ulognl = NULL;

	logfile = NULL;
	amiadaemon = 0;
	tracefeat = 0;
	traceitall = 0;
	ebpfenable = 0;

	if (getuid() != 0) {
		fprintf(stderr, "you need root privileges\n");
		exit(1);
	}

	while ((opt = getopt(argc, argv, "fdbo:teh")) != -1) {
		switch(opt) {
		case 'f':
			break;
		case 'd':
			amiadaemon = 1;
			break;
		case 'o':
			outfile = g_strdup(optarg);
			break;
		case 'b':
			ebpfenable = 1;
			break;
		case 't':
			tracefeat = 1;
			break;
		case 'e':
			traceitall = 1;
			break;
		case 'h':
		default:
			usage(argc, argv);
		}
	}

	if (traceitall && !tracefeat) {
		g_fprintf(stdout, "\nError: -e needs tracing feature (-t) enabled\n");
		usage(argc, argv);
	}

	iptables_init();
	nfnetlink_start();
	iptables_leftovers();

	ret |= iptables_cleanup();
	ret |= add_conntrack();

	if (ret == -1)
		EXITERR("add_conntrack()");

	loop = g_main_loop_new(NULL, FALSE);

	signal(SIGINT, trap);
	signal(SIGTERM, trap);

	if (!outfile)
		outfile = g_strdup("/tmp/conntracker.log");

	initlog(outfile);
	alloc_flows();

	ret = amiadaemon ? makemeadaemon() : dontmakemeadaemon();
	if (ret == -1)
		EXITERR("makemeadaemon");

	// START: netfilter conntrack

	nfcth = nfct_open(CONNTRACK, NF_NETLINK_CONNTRACK_NEW | NF_NETLINK_CONNTRACK_UPDATE);
	if (!nfcth)
		EXITERR("nfct_open");

	nfct_callback_register(nfcth, NFCT_T_ALL, conntrackio_event_cb, NULL);
	nfnlh = (struct nfnl_handle *) nfct_nfnlh(nfcth);
	conntrackio = g_io_channel_unix_new(nfnlh->fd);
	g_io_add_watch(conntrackio, G_IO_IN, conntrackiocb, nfnlh);

	// START: netfilter ulog netlink (through libmnl)

	if (tracefeat) {
		ulognl = ulognlct_open();
		if (!ulognl)
			EXITERR("ulognlct_open");
		ulognlctio = g_io_channel_unix_new(ulognl->fd);
		g_io_add_watch(ulognlctio, G_IO_IN, ulognlctiocb, ulognl);
	}

	// START: bpftracker

	if (ebpfenable) {
		ret |= bpftracker_init();
		if (ret == -1)
			EXITERR("could not init bpftracker");
		g_timeout_add(30, bpftracker_poll, &bpftrackertime);
	}

	// START: main loop

	g_main_loop_run(loop);

	// CLEANUP

	ret |= nfct_close(nfcth);

	if (tracefeat)
		ret |= ulognlct_close(ulognl);

	if (ret == -1)
		EXITERR("closing error")

	g_main_loop_unref(loop);
	cleanup();
	exit(0);
}
