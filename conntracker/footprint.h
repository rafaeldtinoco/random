#ifndef FOOTPRINT_H_
#define FOOTPRINT_H_

#include "general.h"

/* footprints */

struct footprints {
	u8 traced;
	u8 reply;
	GSequence *fp;
	gchar *cmd;
};

struct footprint {
	enum {
		FOOTPRINT_TABLE_RAW = 1,
		FOOTPRINT_TABLE_MANGLE = 2,
		FOOTPRINT_TABLE_NAT = 3,
		FOOTPRINT_TABLE_FILTER = 4,
		FOOTPRINT_TABLE_UNKNOWN = 255
	} table;
	enum {
		FOOTPRINT_TYPE_POLICY = 1,
		FOOTPRINT_TYPE_RULE = 2,
		FOOTPRINT_TYPE_RETURN = 3,
		FOOTPRINT_TYPE_UNKNOWN = 255
	} type;
	/*
	 * chains can be created so they are dynamic
	 * I haven looked at chain name max length
	 */
	char chain[20];
	uint32_t position;
};

gint cmp_footprint(gconstpointer, gconstpointer, gpointer);

gint copy_tcpv4fpcmd(struct in_addr, struct in_addr, u16, u16);

gint add_tcpv4fp(struct in_addr, struct in_addr, u16, u16, struct footprint *);
gint add_udpv4fp(struct in_addr, struct in_addr, u16, u16, struct footprint *);
gint add_icmpv4fp(struct in_addr, struct in_addr, u8, u8, struct footprint *);
gint add_tcpv6fp(struct in6_addr, struct in6_addr, u16, u16, struct footprint *);
gint add_udpv6fp(struct in6_addr, struct in6_addr, u16, u16, struct footprint *);
gint add_icmpv6fp(struct in6_addr, struct in6_addr, u8, u8, struct footprint *);

gint add_tcpv4fpcmd(struct in_addr, struct in_addr, u16, u16, char *);
gint add_udpv4fpcmd(struct in_addr, struct in_addr, u16, u16, char *);
gint add_icmpv4fpcmd(struct in_addr, struct in_addr, u8, u8, char *);
gint add_tcpv6fpcmd(struct in6_addr, struct in6_addr, u16, u16, char *);
gint add_udpv6fpcmd(struct in6_addr, struct in6_addr, u16, u16, char *);
gint add_icmpv6fpcmd(struct in6_addr, struct in6_addr, u8, u8, char *);

void out_footprint(gpointer, gpointer);

void cleanfp(gpointer);

#endif /* FOOTPRINT_H_ */
