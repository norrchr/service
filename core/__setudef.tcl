# core
setudef flag service
setudef flag service_startup
setudef str service_servicebot
setudef int service_userid

# protection
setudef flag service_prot
setudef flag service_prot_hard

# spamscan
setudef flag service_spamscan
setudef int service_stype

# antiflood
setudef flag service_flood
setudef str service_bantime_flood
setudef str service_flood_massjoin

# flyby
setudef flag service_flyby

# auto-op
setudef flag service_ao

# auto-voice
setudef flag service_av

# autolimit
setudef flag service_autolimit
setudef int service_limit

# clonescan
setudef flag service_clonescan
setudef str service_clonescan_bantime
setudef str service_clonescan_maxclones
setudef str service_clonescan_hosttype

# knownonly
setudef flag service_known

# bitchmode
setudef flag service_bitchmode

# badword
setudef flag service_badword
setudef str service_badwords
setudef str service_badword_kickmsg
setudef int service_badword_bantime
setudef int service_badword_bwkid
setudef int service_badword_bwid

# welcome
setudef flag service_welcome
setudef flag service_welcome_notice
setudef str service_welcome_skin

# topic
setudef flag service_topic_save
setudef flag service_topic_force
setudef flag service_topic_Q
setudef str service_topic_skin
setudef str service_topic_current
setudef str service_topic_map

# peak
setudef flag service_peak
setudef int service_peak_count
setudef int service_peak_time
setudef str service_peak_nick

# automsg
setudef flag service_automsg
setudef flag service_automsg_moderate
setudef int service_automsg_last
setudef int service_automsg_counter
setudef int service_automsg_interval
setudef str service_automsg_method
setudef str service_automsg_messages
setudef str service_automsg_maps
# keep for backwards compatibility -- remove in the near future
setudef str service_automsg_line1
setudef str service_automsg_line2
setudef str service_automsg_line3

# enforcemodes
setudef flag service_key
setudef flag service_enforcemodes
setudef str service_enforcedmodes

# netsplit
setudef flag service_netsplit
setudef str service_netsplit_time

# chanmode
setudef str service_chanmode_limit
setudef str service_chanmode_key

# kick messages
setudef str service_kickmsg_kick
setudef str service_kickmsg_ban
setudef str service_kickmsg_protkick
setudef str service_kickmsg_userkick
setudef str service_kickmsg_userban
setudef str service_kickmsg_gban
setudef str service_kickmsg_defaultban
setudef str service_kickmsg_spamkick
setudef str service_kickmsg_spamban
setudef str service_kickmsg_known

# id counters
setudef int service_kid
setudef int service_kid_known
setudef int service_gkid
setudef int service_sid
setudef int service_jid