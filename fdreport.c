/*
 * fdreport; Report on the output from the run of the PATH Driver
 *
 * Copyright (c) E2 Systems, 1994
 *
 * This program expects the following input parameters
 *
 * -h hash table size (default is 2048)
 * -s Start Time
 * -e End Time
 * -w Web Page Output
 * -i percent (SLA percent value)
 * -r real-time format
 * -d Data Format
 * -p Report separate PID values separately
 * -b Report separate bundle values separately
 *
 * Report on the response times recorded in the output file
 *
 * The layout of the file is (colon separated):
 * - bundle identifier
 * - run identifier (PID)
 * - user identifier
 * - stamp sequence
 * - time stamp
 * - stamp type
 * - Further information
 *
 * Pick up the possible events from the A events
 *
 * Add details to the accumulators as the others (except for S, Z, A and F)
 * are found
 *
 * Report by event type afterwards.
 */
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>
#ifdef AIX
#include <sys/time.h>
#else
#ifdef LINUX
#include <sys/time.h>
#endif
#endif
#ifdef OSF
#include <sys/time.h>
#endif
#include <string.h>
#include <errno.h>
#include "hashlib.h"
#include "bmmatch.h"
/*
 * Flag indicating incremental reporting
 */
static int incremental_flag;
static FILE * out_fp;
/*
 * Web Page Title
 */
static char * wtitle = "PATH Response Time Report";
/*
 * SLA Management Configuration
 */
static struct bm_table * type1;
static char * type1_desc;
static double type1_thresh;
static struct bm_table * type2;
static char * type2_desc;
static double type2_thresh;
static struct bm_table * type3;
static char * type3_desc;
static double type3_thresh;
static struct bm_table * type4;
static char * type4_desc;
static double type4_thresh;
static char * unspec_desc;
static double unspec_thresh;
extern double strtod();
extern double floor();
extern double sqrt();
extern double local_secs();
extern char * to_char();
enum time_check {DO,DONT};
enum res_scope {UNIVERSAL, PID, BUNDLE, STRAND};
struct event_def {
char event_id[6];
char comment[132];
};
struct path_rec {
     char *pid;       /* PID */
     int bundle;
     int g;
     int evseq;
     double timestamp;
     char evt[3];
     union {
       struct {
       double timing;
       char * seen;
       int event_cnt[4];
       } result;
       struct event_def *evdef;
     } extra;
};
/*****************************************************************************
 * awk-inspired input line processing
 *
 * Read in a line and return an array of pointers
 */
struct in_rec {
   int fcnt;
   char buf[16384];
   char * fptr[1024];
};
static struct in_rec * cur_rec;
static char * FS = ":\r\n";
/*
 * awk-like input line read routine. If the caller free()s the strdup()'ed
 * line buffer, the pointer to it must be set to NULL. 
 */
static struct in_rec * get_awk(in_rec, fp)
struct in_rec * in_rec;
FILE * fp;
{
int i;

    if (fgets(in_rec->buf,sizeof(in_rec->buf), fp) == (char *) NULL)
        return (struct in_rec *) NULL;
    in_rec->fcnt = 0;
    if (in_rec->fptr[0] != (char *) NULL)
        free(in_rec->fptr[0]);
    in_rec->fptr[0] = strdup(in_rec->buf);
    in_rec->fptr[1] = strtok(in_rec->buf,FS);
    if (in_rec->fptr[1] == (char *) NULL)
        return in_rec;
    if (strlen(in_rec->fptr[1]) == 0)
        i = 1;
    else
        i = 2;
    while ((in_rec->fptr[i] = strtok(NULL, FS)) != (char *) NULL)
        i++;
    in_rec->fcnt = i - 1;
    return in_rec;
}
/**********************************
 * Read a PATH output record
 */
static struct path_rec * get_next(fp)
FILE *fp;
{
static char pid_buf[132];
static struct path_rec work_sess;
unsigned char * x, *parm;
int i;
static struct in_rec in_rec;
/*
 * Come back to this point if corrupt records are encountered
 * Also, for network and web reporting, X, T and R are new record types which
 * otherwise cause the program to crash.
 */
restart:
    if (get_awk( &in_rec, fp) == (struct in_rec *) NULL)
        return NULL;
    if (incremental_flag && !strncmp(in_rec.buf, "===> ",5))
        return NULL;
    if (in_rec.fcnt < 6)
        goto restart; 
    work_sess.pid = pid_buf;
    strcpy(pid_buf, in_rec.fptr[1]);
    work_sess.bundle = atoi(in_rec.fptr[2]); 
    work_sess.g = atoi(in_rec.fptr[3]); 
    work_sess.evseq = atoi(in_rec.fptr[4]); 
    work_sess.timestamp = strtod( in_rec.fptr[5], (char **) NULL)/100.0; 
    strncpy(work_sess.evt,in_rec.fptr[6], sizeof(work_sess.evt));
    work_sess.evt[2] = '\0';
    if (!strcmp(work_sess.evt, "A"))
    {
        if (in_rec.fcnt < 9)
            goto restart;
        work_sess.extra.evdef = (struct event_def *)
                                   malloc(sizeof(struct event_def));
        strncpy(work_sess.extra.evdef->event_id,
                 in_rec.fptr[7], sizeof(work_sess.extra.evdef->event_id));
        work_sess.extra.evdef->event_id[sizeof(work_sess.extra.evdef->event_id)-1] = '\0';
        strncpy(work_sess.extra.evdef->comment, in_rec.fptr[9],
                sizeof(work_sess.extra.evdef->comment));
        work_sess.extra.evdef->comment[sizeof(work_sess.extra.evdef->comment)
                      - 1]= '\0';
    }
    else
    if (strcmp(work_sess.evt,"S")
     && strcmp(work_sess.evt,"F")
     && strcmp(work_sess.evt,"Z"))
    {
        if (in_rec.fcnt < 7 || !strcmp(work_sess.evt, "ZA"))
            goto restart;       /* Skip X, R and T */
        work_sess.extra.result.timing = strtod( in_rec.fptr[7],
                         (char **) NULL)/100.0; 
        for (i = 0; i < 4; i++)
        {
           if (in_rec.fcnt > 8 + i)
               work_sess.extra.result.event_cnt[i] = atoi(in_rec.fptr[8 + i]);
           else
               work_sess.extra.result.event_cnt[i] = 0;
        }
    }
    return &work_sess;
}
struct bun_det {
    char * tran;
    int cps;
    int think;
    int nusers;
    char * seed;
    int cnt;
    double elapsed;
    struct bun_det * next_bun;
};
struct run_struct {
    char * pid;
    double start_time;
    double end_time;
    struct run_struct * next_run;
    struct bun_det * first_bun;
    struct bun_det * last_bun;
};
/*
 * Read in the runout file
 */
static struct run_struct * run_anchor;
static struct run_struct * read_run(pid)
char * pid;
{
FILE * fp;
char buf[2048];

    register struct run_struct * rs;
    sprintf(buf,"runout%s",pid);
    if ((fp = fopen(buf,"rb")) == (FILE *) NULL)
    {
        perror("fopen() failed");
        fprintf(stderr,"Cannot open file %s\n",buf);
        return NULL;
    }
    if ((rs = (struct run_struct *) malloc(sizeof(struct run_struct)))
           == (struct run_struct *) NULL)
    {
         fputs("run_struct malloc() failed\n",stderr);
         exit(1);
    }
/*
 * The run structures are chained together from a single anchor point.
 * Therefore, new records have to be added to the head of the list.
 * So the sequence is:
 * - Allocate the new structure.
 * - Point it at the current anchor value
 * - Set the anchor to point to the freshly allocated structure.
 */
    rs->next_run = run_anchor;
    run_anchor = rs;
    rs->first_bun = (struct bun_det *) NULL;
    rs->last_bun = (struct bun_det *) NULL;
    if ((rs->pid = (char *) malloc(strlen(pid)+1)) == (char *) NULL)
    {
         fputs("pid malloc() failed\n", stderr);
         exit(1);
    }
    rs->start_time = (double) 0.0;
    rs->end_time = (double)999999999999.0;
    strcpy(rs->pid,pid);
/*
 * Loop - pick up the details from the runout file
 */
    while (fgets(buf,sizeof(buf),fp) != (char *) NULL)
    {
    int nusers;
    char tran[80];
    int ntrans;
    char para_1[80];
    int think;
    char para_2[80];
    int cps;
    char seed[40];
    register struct bun_det * bd;
        
        int nf = sscanf(buf, "%d %s %d %d %d %s %s %s",
               &nusers, tran, &ntrans, &think, &cps, seed, para_1, para_2);
        if (nf < 6)
            continue;
        if (!strcmp(tran, "end_time"))
        {
            rs->start_time = (double) nusers;
            rs->end_time = (double) ntrans;
            continue;
        }
        else
        if ((bd = (struct bun_det *) malloc(sizeof(struct bun_det))) == 
                   (struct bun_det *) NULL)
        {
            fputs("bun_det malloc() failed\n",stderr);
            exit(1);
        }
        if (rs->first_bun == (struct bun_det *) NULL)
        {
            rs->first_bun = bd;
        }
        else
            rs->last_bun->next_bun = bd;
        rs->last_bun = bd;
        bd->cnt = 0;
        bd->elapsed = (double) 0.0;
        bd->next_bun = (struct bun_det *) NULL;
        if ((bd->tran = (char *) malloc( strlen(tran)+1)) == (char *) NULL)
        {
             fputs("tran malloc() failed\n",stderr);
             exit(1);
        }
        strcpy(bd->tran,tran);
        bd->cps = cps;
        bd->think = think;
        bd->nusers = nusers;
        if ((bd->seed = (char *) malloc( strlen(seed)+1)) == (char *) NULL)
        {
             fputs("seed malloc() failed\n",stderr);
             exit(1);
        }
        strcpy(bd->seed,seed);
#ifdef DEBUG
        fprintf(stderr,"Bundle: tran %s nusers %d\n",
                 bd->tran, bd->nusers);
        fflush(stderr);
#endif
    }
/*
 * No end of run specified; take everything
 */
    fclose(fp);
    return rs;
}
/***************************************************************
 * Routines that control the collection of timings.
 */

#define MAX_SESS 20480
/*
 * Structure used to batch timings data
 */
struct timbuc {
   int buc_cnt;
   double duration[256];
   struct timbuc * next_buc;
} sla_bucs[6];
/*
 * Structure used to batch timings data
 */
struct whenbuc {
   int when_cnt;
   double when[256];
   double duration[256];
   struct whenbuc * next_when;
} sla_when[6];
/*
 * Structure used to collect timing data
 */
struct collcon {
     struct run_struct * rs;
     struct bun_det * bd;
     struct event_def * ev;
     int sla_class;     /* Values 0 - 4 depending on the classification */
     char desc[132];
     int cnt;
     double tot;
     double tot2;
     double min;
     double max;
     struct timbuc * first_buc;
     struct whenbuc * first_when;
     struct collcon * next_coll;
} sla[6];
/*
 * Handle a set of results
 */
static void inc_tots(un, ts)
struct collcon * un;
struct path_rec * ts;
{
    un->cnt++;
    un->tot += ts->extra.result.timing;
    un->tot2 += (ts->extra.result.timing * ts->extra.result.timing);
    if ( ts->extra.result.timing > un->max)
        un->max = ts->extra.result.timing;
    if ( ts->extra.result.timing < un->min)
        un->min = ts->extra.result.timing;
/*
 * Add another result bucket if needed
 */
    if (un->first_buc->buc_cnt >= 256)
    {
    struct timbuc * x;

        if ((x = (struct timbuc *) malloc(sizeof(struct timbuc))) ==
                       (struct timbuc *) NULL)
        {
            fputs("timbuc malloc() failed\n", stderr);
            exit(1);
        }
        x->next_buc = un->first_buc;
        x->buc_cnt = 0;
        un->first_buc = x;
    }
    un->first_buc->duration[un->first_buc->buc_cnt++]
                        = ts->extra.result.timing;
    return;
}
/*
 * Add a when/response doublet.
 */
static void add_when(un, ts)
struct collcon * un;
struct path_rec * ts;
{
/*
 * Add another result bucket if needed
 */
    if (un->first_when->when_cnt >= 256)
    {
    struct whenbuc * x;

        if ((x = (struct whenbuc *) malloc(sizeof(struct whenbuc))) ==
                       (struct whenbuc *) NULL)
        {
            fputs("whenbuc malloc() failed\n", stderr);
            exit(1);
        }
        x->next_when = un->first_when;
        x->when_cnt = 0;
        un->first_when = x;
    }
    un->first_when->when[un->first_when->when_cnt]
                        = ts->timestamp;
    un->first_when->duration[un->first_when->when_cnt++]
                        = ts->extra.result.timing;
    return;
}
/*
 * Attempt to find an item to update
 */
static struct collcon * attempt_tots(open_sess, cp, ts, realtime_flag)
struct HASH_CON * open_sess;
struct collcon *cp;
struct path_rec * ts;
int realtime_flag;
{
HIPT *h;
struct collcon * un;
/*
 * Ignore it if it if we cannot find its definition
 */
    if ((h = lookup(open_sess, (char *) cp)) == (HIPT *) NULL)
    {
#ifdef DEBUG
        fprintf(stderr,"Cannot Find Event %s\n", ts->evt);
        fflush(stderr);
#endif
        inc_tots(&sla[4], ts);
        if ( ts->extra.result.timing > unspec_thresh)
            add_when(&sla[4], ts);
        return NULL;
    }
    un = ((struct collcon *) (h->body));
    if (!realtime_flag)
        inc_tots(un, ts);
    inc_tots(&sla[un->sla_class], ts);
    if (un->sla_class == 0
       && ts->extra.result.timing > type1_thresh)
        add_when(&sla[0], ts);
    else
    if (un->sla_class == 1
       && ts->extra.result.timing > type2_thresh)
        add_when(&sla[1], ts);
    else
    if (un->sla_class == 2
       && ts->extra.result.timing > type3_thresh)
        add_when(&sla[2], ts);
    else
    if (un->sla_class == 3
       && ts->extra.result.timing > type4_thresh)
        add_when(&sla[3], ts);
    else
    if (un->sla_class == 4
       && ts->extra.result.timing > unspec_thresh)
        add_when(&sla[4], ts);
    return un;
}
/*****************************************************************************
 * Alternative hash functions for the different accumulation cases
 *****************************************************************************
 * Hash the key fields
 */
static int uhash_pid (utp,modulo)
struct collcon * utp;
int modulo;
{
    return (string_hh(utp->rs->pid,modulo) ^
           string_hh(utp->bd->tran,modulo) ^
           string_hh(utp->ev->event_id,modulo)) &(modulo - 1);
}
/*
 * Hash the key fields
 */
static int uhash_bun (utp,modulo)
struct collcon * utp;
int modulo;
{
#ifdef DEBUG
    if (utp == (struct collcon *) NULL)
    {
        fputs("Hashed NULL utp\n", stderr);
        fflush(stderr);
        return 0;
    }
    else
    if (utp->bd == (struct bun_det *) NULL)
    {
        fputs("Hashed NULL utp->bd\n", stderr);
        fflush(stderr);
        return 0;
    }
    else
    if (utp->bd->tran == (char *) NULL)
    {
        fputs("Hashed NULL utp->bd->tran\n",stderr);
        fflush(stderr);
        return 0;
    }
    else
    if (utp->ev == (struct event_def *) NULL)
    {
        fputs("Hashed NULL utp->ev\n",stderr);
        fflush(stderr);
        return 0;
    }
    else
    if (utp->ev->event_id == (char *) NULL)
    {
        fputs("Hashed NULL utp->ev->event_id\n",stderr);
        fflush(stderr);
        return 0;
    }
    fprintf(stderr,"Key: %s %s\n",utp->bd->tran,utp->ev->event_id);
    fflush(stderr);
#endif
    return ( string_hh(utp->bd->tran,modulo) ^
           string_hh(utp->ev->event_id,modulo)) &(modulo - 1);
}
static int uhash_uni (utp,modulo)
struct collcon * utp;
int modulo;
{
    return ( string_hh(utp->ev->event_id,modulo)) &(modulo - 1);
}
/*
 * Compare pairs of key fields
 */
static int ucomp_pid(utp1,  utp2)
struct collcon * utp1;
struct collcon * utp2;
{
    int i;
    return ((i = strcmp(utp1->rs->pid, utp2->rs->pid)) ? i :
           ((i = strcmp(utp1->bd->tran, utp2->bd->tran)) ? i :
           (strcmp(utp1->ev->event_id, utp2->ev->event_id))));
}
static int ucomp_bun(utp1,  utp2)
struct collcon * utp1;
struct collcon * utp2;
{
    int i;
    return (((i = strcmp(utp1->bd->tran, utp2->bd->tran)) ? i :
           (strcmp(utp1->ev->event_id, utp2->ev->event_id))));
}
static int ucomp_uni(utp1,  utp2)
struct collcon * utp1;
struct collcon * utp2;
{
    return ((strcmp(utp1->ev->event_id, utp2->ev->event_id)));
}
static int double_comp(i,j)
double *i;
double *j;
{
    if (*i == *j)
        return 0;
    else
    if (*i < *j)
        return -1;
    else
        return 1;
}
/***********************************************************************
 * Getopt support
 */
extern int optind;           /* Current Argument counter.      */
extern char *optarg;         /* Current Argument pointer.      */
extern int opterr;           /* getopt() err print flag.       */
extern int errno;

static char * date_format=(char *) NULL;
                          /* date format expected of data arguments */
/*
 * Fix up text so GNUPLOT doesn't interpret it
 */
static char * fix_up_name(nm)
char * nm;
{
static char rname[128];
char * x = nm;
char * x1 = &rname[0];

    while(x1 < &rname[127] && *x != '\0')
    {
       if (*x == '_')
       {
          *x1++ = '\\';
          *x1++ = '\\';
       }
       *x1++ = *x++;
   }
   *x1 = '\0';
   return &rname[0];
}
static char graph_name[128];
static int g_seq;
/*
 * Run gnuplot to produce a pctile graph
 */
static char * do_pctile_graph(un, mn, pc1, pc2, pc3, pc4, pc5, pc6, pc7, pc8, pc9, mx)
struct collcon * un;
double mn;
double pc1;
double pc2;
double pc3;
double pc4;
double pc5;
double pc6;
double pc7;
double pc8;
double pc9;
double mx;
{
FILE * ofp;
char * narr;
double ymax;

    if ((ofp = popen("gnuplot -", "w")) != (FILE *) NULL)
    {
        narr = fix_up_name(un->desc);
#ifdef GENERATE_SVG
        sprintf(graph_name, "pctile_%d.svg", g_seq++); 
#else
        sprintf(graph_name, "pctile_%d.png", g_seq++); 
#endif
        if (mx < 1.0)
            ymax = 1.0;
        else
        if (mx < 5.0)
            ymax = 5.0;
        else
            ymax = (floor(mx/10.0)*10.0 + 10.0);
#ifdef GENERATE_SVG
        fprintf(ofp, "set terminal svg enhanced font \"sans\" fsize 10 size 640 480\n\
set output '%s'\n\
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0 \n\
set xtics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0 \n\
set xtics ('0%%%%' 0.0000, '10%%%%' 10.0000, '20%%%%' 20.0000, '30%%%%' 30.0000, '40%%%%' 40.000, '50%%%%' 50.000, '60%%%%' 60.0000, '70%%%%' 70.000, '80%%%%' 80.000, '90%%%%' 90.000, '100%%%%' 100.000)\n\
set title \"%s\\nPercentile Response Times\" font 'sans,14'\n\
set xrange [ 0 : 100 ] noreverse nowriteback\n\
set yrange [ 0.0000 : %.3f ] noreverse nowriteback\n\
set lmargin 9\n\
set rmargin 2\n\
set ylabel 'Response Time/seconds' offset 1 font 'sans,12'\n\
set xlabel 'Percentiles (%d readings)' offset 1 font 'sans,12'\n\
plot '-' using 1:2 notitle with lines\n",
                    graph_name, narr, ymax, un->cnt );
#else
        fprintf(ofp, "set terminal png nocrop enhanced font a010015l 10 size 640,480\n\
set output '%s'\n\
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0 \n\
set xtics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0 \n\
set xtics ('0%%%%' 0.0000, '10%%%%' 10.0000, '20%%%%' 20.0000, '30%%%%' 30.0000, '40%%%%' 40.000, '50%%%%' 50.000, '60%%%%' 60.0000, '70%%%%' 70.000, '80%%%%' 80.000, '90%%%%' 90.000, '100%%%%' 100.000)\n\
set title \"%s\\nPercentile Response Times\" font 'a010015l,14'\n\
set xrange [ 0 : 100 ] noreverse nowriteback\n\
set yrange [ 0.0000 : %.3f ] noreverse nowriteback\n\
set lmargin 9\n\
set rmargin 2\n\
set ylabel 'Response Time/seconds' offset 1 font 'a010015l,12'\n\
set xlabel 'Percentiles (%d readings)' offset 1 font 'a010015l,12'\n\
plot '-' using 1:2 notitle with lines\n",
                    graph_name, narr, ymax, un->cnt );
#endif
        fprintf(ofp, "0 %.3f\n", mn);
        fprintf(ofp, "10 %.3f\n", pc1);
        fprintf(ofp, "20 %.3f\n", pc2);
        fprintf(ofp, "30 %.3f\n", pc3);
        fprintf(ofp, "40 %.3f\n", pc4);
        fprintf(ofp, "50 %.3f\n", pc5);
        fprintf(ofp, "60 %.3f\n", pc6);
        fprintf(ofp, "70 %.3f\n", pc7);
        fprintf(ofp, "80 %.3f\n", pc8);
        fprintf(ofp, "90 %.3f\n", pc9);
        fprintf(ofp, "100 %.3f\n", mx);
        fputs("e\n", ofp);
        pclose(ofp);
        return graph_name;
    }
    return NULL;
}
/*
 * Graph when SLA Breaches occurred
 */
static char * do_slow_graph(un)
struct collcon * un;
{
FILE * ofp;
char * narr;
double maxy;
double beg_ts;
double end_ts;
char beg_time[25];
char end_time[25];
int i;
struct whenbuc * wp;
int rdgs;
/*
 * Return if there aren't any
 */
    if (un->first_when->when_cnt == 0)
        return NULL;
/*
 * Find the beginning and end times, the count
 * and the top of the Y scale.
 */
    for (rdgs = 0,
         end_ts = 0.0,
         beg_ts = 9999999999.0,
         maxy =0.0,
         wp = un->first_when;
            wp != NULL;
                wp = wp->next_when)
        for (i = 0; i < wp->when_cnt; i++, rdgs++)
        {
            if (wp->when[i] < beg_ts)
                beg_ts = wp->when[i];
            if (wp->when[i] > end_ts)
                end_ts = wp->when[i];
            if (wp->duration[i] > maxy)
                maxy = wp->duration[i];
        }
    sprintf(beg_time, "%s",       
             to_char("dd Mon yyyy hh24:mi:ss",
                local_secs((time_t)beg_ts)));
    sprintf(end_time, "%s",       
             to_char("dd Mon yyyy hh24:mi:ss",
                local_secs((time_t)end_ts)));

    if ((ofp = popen("gnuplot -", "w")) != (FILE *) NULL)
    {
        narr = fix_up_name(un->desc);
#ifdef GENERATE_SVG
        sprintf(graph_name, "longxy_%d.svg", g_seq++); 
        fprintf(ofp, "set terminal svg enhanced font \"sans\" fsize 10 size 640 480\n\
set output '%s'\n\
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0\n\
set title \"%s\\nResponse Times Over Threshold\" font  'sans,14'\n\
set xdata time\n\
set yrange [ 0.0000 : %.3f ] noreverse nowriteback\n\
set timefmt \"%%d %%b %%Y %%H:%%M:%%S\"\n\
set xrange [ \"%s\" : \"%s\" ] noreverse nowriteback\n\
set format x \"%%R\"\n\
set xtics border out scale 1,0.5 mirror norotate  offset character 0, 0, 0\n\
set xlabel 'Time (%d readings)' offset 1 font  'sans,12'\n\
#set size 1, 0.5\n\
set ylabel 'Response/seconds' font  'sans,12'\n\
plot '-' using 1:5 notitle with points\n", graph_name, narr, maxy,
beg_time,
end_time, rdgs);
#else
        sprintf(graph_name, "longxy_%d.png", g_seq++); 
        fprintf(ofp,
"set terminal png nocrop enhanced font a010015l 10 size 640,480\n\
set output '%s'\n\
set ytics border out scale 1,0.5 nomirror norotate  offset character 0, 0, 0\n\
set title \"%s\\nResponse Times Over Threshold\" font  'a010015l,14'\n\
set xdata time\n\
set yrange [ 0.0000 : %.3f ] noreverse nowriteback\n\
set timefmt \"%%d %%b %%Y %%H:%%M:%%S\"\n\
set xrange [ \"%s\" : \"%s\" ] noreverse nowriteback\n\
set format x \"%%R\"\n\
set xtics border out scale 1,0.5 mirror norotate  offset character 0, 0, 0\n\
set xlabel 'Time (%d readings)' offset 1 font  'a010015l,12'\n\
#set size 1, 0.5\n\
set ylabel 'Response/seconds' font 'a010015l,12'\n\
plot '-' using 1:5 notitle with points\n", graph_name, narr, maxy,
beg_time,
end_time, rdgs);
#endif
/*
 * Now output the X/Y plot values.
 */
    for (wp = un->first_when;
            wp != NULL;
                wp = wp->next_when)
        for (i = 0; i < wp->when_cnt; i++, rdgs++)
            fprintf(ofp,"%s %.3f\n",
             to_char("dd Mon yyyy hh24:mi:ss",
                local_secs((time_t) wp->when[i])),
                wp->duration[i]);
        fputs("e\n", ofp);
        pclose(ofp);
        return graph_name;
    }
    return NULL;
}
/*****************************************************************************
 * Output the details FIFO style, so that the order is the one expected by
 * the reader
 */
static void reverse_print(un, off_flag, do_95)
struct collcon * un;
int off_flag;
double do_95;
{
double av,sd,mn,pc1,pc2,pc3,pc4,pc5,pc6,pc7,pc8,pc9,mx,c,pc95;
double *x, *y, *sa, *sortlist;
struct timbuc * tb;
int i;
char * graph_name;

    if (un == (struct collcon *) NULL)
        return;
    if (un->next_coll != (struct collcon *) NULL)
        reverse_print(un->next_coll, off_flag, do_95);
    if (un->cnt == 0)
    {
#ifdef DEBUG
        fprintf(stderr,"No events for %s\n", un->desc);
        fflush(stderr);
#endif
        return;
    }
    if ((sortlist = (double *) malloc( un->cnt * sizeof(double))) ==
            (double *) NULL)
    {
         fputs("run_struct malloc() failed\n", stderr);
         exit(1);
    }
    for (x = sortlist,
         tb = un->first_buc;
             tb != (struct timbuc *) NULL;
                  tb = tb->next_buc)
         for (i = 0, y = &tb->duration[0]; i < tb->buc_cnt; i++)
             *x++ = *y++;
    qsort(sortlist,un->cnt,sizeof(double),double_comp); 
    mn = floor( 1000.0 * un->min+.5)/1000.0;
    mx = floor( 1000.0 * un->max+.5)/1000.0;
    av = floor( 1000.0 * un->tot/un->cnt+.5)/1000.0;
    if ( (un->tot2 - un->tot/un->cnt*un->tot) > (double) 0.0)
        sd = floor( 1000.0 * sqrt(un->tot2 - un->tot/un->cnt*un->tot)
                /un->cnt+.5)/ 1000.0;
    else
        sd = (double) 0.0;
    c = (double) un->cnt;
    sa = sortlist + (int)floor(.1*c);
    pc1 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(.2*c);
    pc2 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(.3*c);
    pc3 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(.4*c);
    pc4 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(.5*c);
    pc5 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(.6*c);
    pc6 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(.7*c);
    pc7 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(.8*c);
    pc8 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(.9*c);
    pc9 = floor(*sa * 1000.0+.5)/1000.0;
    sa = sortlist + (int)floor(( do_95)/100.0*c);
    pc95 = floor(*sa * 1000.0+.5)/1000.0;
    if (!off_flag)
    {
        if (do_95 != 0.0)
        {
            fprintf(out_fp, "%-44.44s %5.1d %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f \
%5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f\n",
                    un->desc,
                    un->cnt,
                    av,sd,pc95,mn,pc1,pc2,pc3,pc4,pc5,pc6,pc7,pc8,pc9,mx);
        }
        else
        {
            fprintf(out_fp, "%-44.44s %5.1d %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f \
%5.2f %5.2f %5.2f %5.2f %5.2f %5.2f\n",
                    un->desc,
                    un->cnt,
                    av,sd,mn,pc1,pc2,pc3,pc4,pc5,pc6,pc7,pc8,pc9,mx);
        }
    }
    else
    if (off_flag == -1)
    {
        if (un->sla_class == 0)
        {
/*
 * 95 percentile better than 2 seconds
 */
            if (av > type1_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff0000\"><td ");
            else
            if (pc95 > type1_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff8000\"><td ");
            else
                fprintf(out_fp, "<tr style=\"background-color: #ffffff\"><td ");
        }
        else
        if (un->sla_class == 1)
        {
/*
 * 95 percentile better than 7 seconds
 */
            if (av > type2_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff0040\"><td ");
            else
            if (pc95 > type2_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff8040\"><td ");
            else
                fprintf(out_fp, "<tr style=\"background-color: #ffffff\"><td ");
        }
        else
        if (un->sla_class == 2)
        {
/*
 * 95 percentile better than 10 seconds
 */
            if (av > type3_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff0080\"><td ");
            else
            if (pc95 > type3_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff8080\"><td ");
            else
                fprintf(out_fp, "<tr style=\"background-color: #ffffff\"><td ");
        }
        else
        if (un->sla_class == 3)
        {
/*
 * 95 percentile better than 10 seconds
 */
            if (av > type4_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff00c0\"><td ");
            else
            if (pc95 > type4_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff80c0\"><td ");
            else
                fprintf(out_fp, "<tr style=\"background-color: #ffffff\"><td ");
        }
        else
        {
            if (av > unspec_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff0000\"><td ");
            else
            if (pc95 > unspec_thresh)
                fprintf(out_fp, "<tr style=\"background-color: #ff8000\"><td ");
            else
                fprintf(out_fp, "<tr style=\"background-color: #ffffff\"><td ");
        }
        if (un->cnt >= 10
           && (graph_name = do_pctile_graph(un, mn, pc1, pc2, pc3, pc4, pc5,
                     pc6, pc7, pc8, pc9, mx)) != NULL)
        {
#ifdef GENERATE_SVG
                fprintf(out_fp, " onMouseOver = \"shoh('%s')\"  onMouseOut = \"shoh('%s')\"><iframe style=\"background-color:white;display:none;\" id=\"%s\" name=\"%s\" src=\"%s\" frameborder=\"0\" height=\"480\" width=\"640\"></iframe>%s\r\n",
                    graph_name,graph_name, graph_name,
                    graph_name,graph_name, un->desc);
#else
                fprintf(out_fp, " onMouseOver = \"shoh('%s')\"  onMouseOut = \"shoh('%s')\"><img style=\"display: none\" id=\"%s\" name=\"%s\" src=\"%s\" alt=\"%s\" />%s\r\n",
                    graph_name,graph_name, graph_name,
                    graph_name,graph_name, un->desc, un->desc);
#endif
             
        }
        else
            fprintf(out_fp, ">%s", un->desc);
        fprintf(out_fp, "</td><td>%5.1d</td><td>%7.3f</td><td>%7.3f</td>",
                    un->cnt,
                    av,sd);
        if (do_95 != 0.0)
        {
            sa = sortlist + (int)floor((do_95)/100.0*c);
            pc95 = floor(*sa * 1000.0+.5)/1000.0;
            fprintf(out_fp, "<td>%7.3f</td>", pc95);
        }
        fprintf(out_fp, 
"<td>%7.3f</td><td>%7.3f</td><td>%7.3f</td><td>%7.3f</td><td>%7.3f</td><td>%7.3f</td><td>%7.3f</td><td>%7.3f</td><td>%7.3f</td><td>%7.3f</td><td>%7.3f</td></tr>\r\n",
mn,pc1,pc2,pc3,pc4,pc5,pc6,pc7,pc8,pc9,mx);
    }
    else
    {
        if (do_95 != 0.0)
        {
            sa = sortlist + (int)floor((do_95)/100.0*c);
            pc95 = floor(*sa * 1000.0+.5)/1000.0;
            fprintf(out_fp, "%s\t%5.1d\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t\
%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\n",
                    un->desc,
                    un->cnt,
                    av,sd,pc95,mn,pc1,pc2,pc3,pc4,pc5,pc6,pc7,pc8,pc9,mx);
        }
        else
        {
            fprintf(out_fp, "%s\t%5.1d\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t\
%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\t%6.3f\n",
                    un->desc,
                    un->cnt,
                    av,sd,mn,pc1,pc2,pc3,pc4,pc5,pc6,pc7,pc8,pc9,mx);
        }
    }
    free(sortlist);
    return;
}
/*
 * Find the corresponding bundle
 */
static struct bun_det * loc_bun(rs, bun)
struct run_struct * rs;
int bun;
{
struct bun_det * bd;
int i;

    for (bd = rs->first_bun, i = 0;
            i < (bun - 1) && bd != (struct bun_det *) NULL;
                bd = bd->next_bun, i++);
    return bd;
}
/*
 * Output the exceptional events web header
 */
static void print_exception_header()
{
    fputs("<h1 onMouseOver = \"shoh('exc_eve')\"  onMouseOut = \"shoh('exc_eve')\">\r\nExceptional Events\r\n", out_fp);
    fputs(
"<table id='exc_eve' name='exc_eve' style=\"background-color:white;display:none;\" cellpadding='1' cellspacing='1' border='1'>\r\n\
<tr><th>PID</th><th>Bundle</th><th>Rope</th><th>Sequence</th><th>When</th><th>How Long</th><th>What</th></tr>\r\n", out_fp);
    return;
}
/*
 * Do one FP; process a file pointer until EOF
 */
void do_one_fp(fp, open_sess, res_scope, time_check, first_time, last_time,
last_pid, last_bun, anchorp, cp, rsp, done_aborts, off_flag, realtime_flag, suppress_flag,sep_char)
FILE * fp;
struct HASH_CON * open_sess;
enum res_scope res_scope;
enum time_check time_check;
time_t first_time;
time_t last_time;
char * last_pid;       /* Run Identifier */
int * last_bun;        /* Run Identifier */
struct collcon ** anchorp;
struct collcon * cp;
struct run_struct ** rsp;
int * done_aborts;
int off_flag;
int realtime_flag;
int suppress_flag;
char sep_char;
{
struct collcon * un = NULL;
struct event_def tev;
double sttime;
struct path_rec * ts;

    for (ts = get_next(fp);
            ts != (struct path_rec *) NULL;
                ts = get_next(fp))
    {
/*
 * Read in the PID file if necessary
 */
#ifdef DEBUG
    static int ij;

        fprintf(stderr,"Record:%d\n",++ij);
        fflush(stderr);
#endif
        if (strcmp(last_pid, ts->pid))
        {
            strcpy(last_pid, ts->pid);
            *rsp = read_run(last_pid);
            cp->bd = NULL;
            *last_bun = 0;
#ifdef DEBUG
            fprintf(stderr,"Record:%d New Pid: %s\n",ij,ts->pid);
            fflush(stderr);
#endif
        }
        if (*rsp != (struct run_struct *) NULL)
            cp->rs = *rsp;
        if (cp->rs != (struct run_struct *) NULL &&
                first_time > cp->rs->start_time)
            cp->rs->start_time = first_time;
        if (cp->rs != (struct run_struct *) NULL &&
                last_time < cp->rs->end_time)
            cp->rs->start_time = first_time;
/*
 * Process the record according to type
 */
#ifdef DEBUG
        fprintf(stderr,"Reached strcmp\n");
        fflush(stderr);
#endif
        if (cp->rs == (struct run_struct *) NULL && res_scope != UNIVERSAL)
            continue;        /* Can't do anything without this */
/*
 * Find the matching bundle
 */
        if (cp->bd == (struct bun_det *) NULL
         || *last_bun != ts->bundle)
        {
            if (cp->rs == (struct run_struct *) NULL
              || (cp->bd = loc_bun(cp->rs, ts->bundle)) == (struct bun_det *) NULL)
            {
                 fprintf(stderr,"Cannot find bundle ts->bundle %d for %s\n",
                      ts->bundle, ts->pid);
                 fflush(stderr);
/*
 * Ignore it if we cannot find its definition and we need it
 */
                 if (res_scope != UNIVERSAL)
                     continue;        /* Can't do anything without this */
            }
            *last_bun = ts->bundle;
        }
        if (!strcmp(ts->evt, "S"))
        {
            sttime = ts->timestamp;   
            if (time_check == DO && sttime < (double) first_time)
                sttime = (double) first_time; 
            else
            if (cp->rs != (struct run_struct *) NULL &&
                    sttime < cp->rs->start_time)
                sttime = cp->rs->start_time;
        }
        else
        if (!strcmp(ts->evt, "A"))
        {
        HIPT *h;
#ifdef DEBUG
        fputs("Before tcon\n", stderr);
        fflush(stderr);
#endif
            cp->ev = ts->extra.evdef;
#ifdef DEBUG
        fprintf(stderr,"open_sess : %x cp: %x\n", (long) open_sess,
                               (long) cp);
        fflush(stderr);
#endif
            if ((h = lookup(open_sess, (char *) cp)) == (HIPT *) NULL)
            {
            char * x;
            short int *y;
#ifdef DEBUG
        fputs("Before timbuc allocation\n",stderr);
        fflush(stderr);
#endif
                if ((cp->first_buc = (struct timbuc *)
                                   malloc(sizeof(struct timbuc)))
                     == (struct timbuc *) NULL)
                {
                     fputs("timbuc malloc() failed\n", stderr);
                     exit(1);
                }
                cp->first_buc->buc_cnt = 0;
                cp->first_buc->next_buc = (struct timbuc *) NULL;
                if ((un = (struct collcon *) malloc(sizeof(struct collcon)))
                     == (struct collcon *) NULL)
                {
                     fputs("un malloc() failed\n", stderr);
                     exit(1);
                }
                *(un) = *cp;
                un->next_coll = *anchorp;
                *anchorp = un;
#ifdef DEBUG
        fputs("Before insert\n" ,stderr);
        fflush(stderr);
#endif
                insert(open_sess,(char *) un, (char *) un);
                x = (*anchorp)->desc;
                if (cp->rs != (struct run_struct *) NULL
                 && res_scope == PID)
                    x += sprintf(x,"%s:",cp->rs->pid);
                if (cp->bd != (struct bun_det *) NULL &&
                    cp->bd->tran != (char *) NULL &&
                    (res_scope == PID || res_scope == BUNDLE))
                    x += sprintf(x,"%s:",cp->bd->tran);
#ifdef DEBUG
        fputs("Before comment save\n", stderr);
        fprintf(stderr,
                "anchor; %x anchor->ev; %x anchor->ev->comment; %x\n",
                   (long) *anchorp, (long) ((*anchorp)->ev),
                   (long) ((*anchorp)->ev->comment));
        fflush(stderr);
#endif
                if ((*anchorp)->ev != (struct event_def *) NULL)
                {
                    if (bm_match(type1, (*anchorp)->ev->comment,
                              (*anchorp)->ev->comment + 44))
                        (*anchorp)->sla_class = 0;
                    else
                    if (bm_match(type2, (*anchorp)->ev->comment,
                              (*anchorp)->ev->comment + 44))
                        (*anchorp)->sla_class = 1;
                    else
                    if (bm_match(type3, (*anchorp)->ev->comment,
                              (*anchorp)->ev->comment + 44))
                        (*anchorp)->sla_class = 2;
                    else
                    if (bm_match(type4, (*anchorp)->ev->comment,
                              (*anchorp)->ev->comment + 44))
                        (*anchorp)->sla_class = 3;
                    else
                    {
                        (*anchorp)->sla_class = 4;
                        fprintf(stderr, "Unspecified: %s\n",
                                        (*anchorp)->ev->comment);
                    }
                    strncpy(x, (*anchorp)->ev->comment,
                         ((*anchorp)->desc + sizeof((*anchorp)->desc)) -x -1);
                    (*anchorp)->desc[sizeof((*anchorp)->desc) - 1] = '\0';
                }
                else
                {
                    (*anchorp)->sla_class = 4;
                    strcpy(x,"No description");
                }
            }
#ifdef DEBUG
            else
            {
                fputs("Already seen\n", stderr);
                fflush(stderr);
            }
#endif
        }        
        else
        if (!strcmp(ts->evt, "F"))
        {
            if (time_check == DO && ts->timestamp > (double) last_time)
                ts->timestamp = (double) last_time; 
            else
            if (cp->rs != (struct run_struct *) NULL &&
                     ts->timestamp > cp->rs->end_time)
                ts->timestamp = cp->rs->end_time;
            if (cp->bd != NULL)
            {
                cp->bd->elapsed += ts->timestamp - sttime;   
                cp->bd->cnt++;
                cp->bd = NULL;
            }
            *last_bun = 0;
        }
        else
        if (!strcmp(ts->evt, "Z"))
        {
            if (!suppress_flag)
            {
                if (cp->rs != (struct run_struct *) NULL &&
                      ts->timestamp < cp->rs->end_time) 
                {
                    if (off_flag == -1)
                    {
                        if (!*done_aborts)
                        {
                            print_exception_header();
                            *done_aborts = 1;
                        }
                        fprintf(out_fp, 
"<tr><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td></tr>\r\n",
                         ts->pid,ts->bundle,ts->g, ts->evseq,
                         to_char("dd Mon yyyy hh24:mi:ss",
                                 local_secs((time_t)ts->timestamp)));
                    }
                    else
                        fprintf(out_fp, "Abort Event Detected.. PID %s Bundle %d g %d Seq %d\n",
                         ts->pid,ts->bundle,ts->g, ts->evseq);
                }
            }
        }
        else
        {   /* Ordinary Event */
/*
 * Ignore it if it is outside the time period of interest
 */
            if ((time_check == DO && (ts->timestamp > (double) last_time ||
                ts->timestamp < (double) first_time)) ||
                (res_scope != UNIVERSAL &&
                (cp->rs == (struct run_struct *) NULL ||
                ts->timestamp < cp->rs->start_time
                 || ts->timestamp > cp->rs->end_time)))
            {
#ifdef DEBUG
                fputs("Out of Time\n", stderr);
                fflush(stderr);
#endif
                continue;
            }
            if (suppress_flag == -1)
            {
                fprintf(out_fp, 
"%s%c%d%c%d%c%d%c%s%c%-17.6f%c%d%c%d%c%d%c%d%c%-.3f%c%s\n",
                 ts->pid, sep_char,
                 ts->bundle, sep_char,
                 ts->g, sep_char,
                 ts->evseq, sep_char,
                 to_char("dd Mon yyyy hh24:mi:ss",
                         local_secs((time_t)ts->timestamp)), sep_char,
                 ts->timestamp, sep_char,
                 ts->extra.result.event_cnt[0], sep_char,
                 ts->extra.result.event_cnt[1], sep_char,
                 ts->extra.result.event_cnt[2], sep_char,
                 ts->extra.result.event_cnt[3], sep_char,
                 ts->extra.result.timing, sep_char,
                    (un == NULL) ? "" : ((un->desc == NULL) ? "" :
                              un->desc));
            }
            else
            {
/*
 * Just put this record in the error bucket if failure is signalled.
 * event_cnt[3] is Good seen. event_cnt[0], [1] and [2] are various
 * categories of error.
 */
                if (ts->extra.result.event_cnt[3] == 0   /* Good Seen               */
                 && (ts->extra.result.event_cnt[2] != 0  /* Error Seen              */
                 || ts->extra.result.event_cnt[1] != 0   /* Server Error (HTTP 5xx) */
                /* || ts->extra.result.event_cnt[0] != 0 */ )) /* HTTP Error (HTTP 4xx)   */
                {
                    inc_tots(&sla[5], ts);
                    add_when(&sla[5], ts);
                }
                else
                {
                    cp->ev = &tev;
                    strcpy(tev.event_id, ts->evt);
                    un = attempt_tots(open_sess, cp, ts, realtime_flag);
                    if ( (realtime_flag || off_flag == -1)
                      && un != NULL
                      && (( un->sla_class == 0 && ts->extra.result.timing > type1_thresh)
                       || ( un->sla_class == 1 && ts->extra.result.timing > type2_thresh)
                       || ( un->sla_class == 2 && ts->extra.result.timing > type3_thresh)
                       || ( un->sla_class == 3 && ts->extra.result.timing > type4_thresh)
                       || ( un->sla_class == 4 && ts->extra.result.timing > unspec_thresh)))
                    {
                        if (off_flag == -1)
                        {
                            if (!*done_aborts)
                            {
                                print_exception_header();
                                *done_aborts = 1;
                            }
                            fprintf(out_fp, 
"<tr><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td><td>%.3f</td><td>%s</d></tr>\r\n",
                             ts->pid,ts->bundle,ts->g, ts->evseq,
                             to_char("dd Mon yyyy hh24:mi:ss",
                                 local_secs((time_t)ts->timestamp)),
                                ts->extra.result.timing, un->desc);
                        }
                        else
                            fprintf(out_fp, "Slow ... PID %s Bundle %d g %d Seq %d Time %.3f:%s\n",
                                 ts->pid,ts->bundle,ts->g, ts->evseq,
                                    ts->extra.result.timing, un->desc);
                    }
                }
            }
        }
    }
    return;
}
/*********************************************************************
 * Main program starts here
 * VVVVVVVVVVVVVVVVVVVVVVVV
 */
main(argc,argv,envp)
int argc;
char ** argv;
char ** envp;
{
char * html_head;
char * html_tail;
char * out_fname;
int off_flag;
int suppress_flag = 0;
double do_95;
char sep_char;
struct collcon * anchor;
int i;
HASH_CON * open_sess;
int realtime_flag = 0;
time_t first_time;
time_t last_time;
double valid_time;       /* needed for the date check */
char * x;                /* needed for the date check */
int c;
enum time_check time_check;
enum res_scope res_scope;
int hash_size = MAX_SESS;
struct tm * cur_tm;
FILE *fp = (FILE *) NULL;
int done_aborts = 0;
char last_pid[120];       /* Run Identifier */
int last_bun;             /* Run Identifier */
struct run_struct * rs;
struct collcon tcon;
struct bun_det * bd;
/*
 * Validate the arguments
 */
    time_check = DONT;
    first_time = 0;
    last_time = time(0);
    cur_tm = gmtime(&last_time);
    off_flag = 0;
    do_95 = 0.0;
    out_fp = stdout;
#ifdef MINGW32
    _putenv("GDFONTPATH=/usr/share/fonts/type1/gsfonts");
#else
    setenv("GDFONTPATH", "/usr/share/fonts/type1/gsfonts", 1);
#endif
    if (cur_tm->tm_isdst > 0)
        last_time += 3600;
    res_scope = UNIVERSAL;
    sep_char = ' ';
    while ( ( c = getopt( argc, argv, "uh:pbd:s:e:rtw:i:zo:x:" ) ) != EOF )
    {
        switch ( c )
        {
        case 'h':
             hash_size  = atoi(optarg);
             if (hash_size < 100)
                 hash_size = MAX_SESS;
             break;
        case 'o':
             off_flag = -1;
             out_fname = optarg;
             if ((out_fp = fopen(out_fname, "wb")) == NULL)
                 out_fp = stdout;
             incremental_flag = 1;
             realtime_flag = 1;
             break;
        case 'r':
             realtime_flag = 1;
             break;
        case 't':
             off_flag = 1;
             sep_char = '\t';
             break;
        case 'w':
             off_flag = -1;
             if (strlen(optarg) > 0)
                 wtitle = optarg;
             break;
        case 'z':
             suppress_flag = 1;
             break;
        case 'i':
             do_95 = strtod(optarg, NULL);
             break;
        case 'd':
             date_format = optarg;
             break;
        case 'u' :
             res_scope = STRAND;
             break;
        case 'x' :
             suppress_flag = -1;
             sep_char = *optarg;
             break;
        case 'b' :
             res_scope = BUNDLE;
             break;
        case 'p' :
             res_scope = PID;
             break;
        case 'e' :
        case 's' :
            time_check = DO;
            if ( date_format != (char *) NULL)
            {
                if (!date_val(optarg,date_format,&x,&valid_time))
    /*
     * Time argument is not a valid date
     */
                {
                    (void) fprintf(stderr, "Invalid date %s for format %s\n",
                        optarg, date_format);
                    exit(0);
                }
                if (c == 's')
                    first_time = (time_t)
                        (valid_time - ((cur_tm->tm_isdst > 0)?3600:0));
                else
                    last_time = (time_t)
                        (valid_time - ((cur_tm->tm_isdst > 0)?3600:0));
            }
            else
            {
                if (c == 's')
                    first_time = (time_t) atoi(optarg);
                else
                    last_time =  (time_t) atoi(optarg);
            }
            break;

        default:
        case '?' : /* Default - invalid opt.*/
               (void) puts("fdreport - Report the outcome of a run\n\
Options:\n\
 -h hash table size (default is 2048)\n\
 -s Start Time\n\
 -e End Time\n\
 -d Date Format\n\
 -i Include a particular percentile (percentile)\n\
 -o Incrementally write out result to the given file. Implies -r and -w.\n\
 -r Real-time; SLA summary plus long responses only.\n\
 -t Format output for Microsoft Office\n\
 -w Format as a Web Page; provide a title\n\
 -x export separated data (separator)\n\
 -z Ignore Z events\n\
 -u Report separate PID strand values separately (not implemented)\n\
 -p Report separate PID values separately\n\
 -b Report separate bundle values separately (the same event in different scripts is not the same)\n\
Then either a list of filenames (that can include - for stdin) or nothing\n\
If no file arguments are provided, stdin is read\n\
The output goes to stdout");
               exit(1);
            break;
       }
    }
    if (suppress_flag == -1)
        fprintf(out_fp, 
"%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s\n",
    "RunID", sep_char, "Bundle", sep_char, "Thread", sep_char,
    "Sequence", sep_char, "DateTime", sep_char, "Timestamp", sep_char,
    "HTTPErrors", sep_char, "ServerErrors", sep_char, "ApplicationErrors", sep_char,
    "ApplicationSuccesses", sep_char, "ResponseTime", sep_char, "Narrative");
/*
 * Response time classification details for SLA purposes.
 */
    if (((x = getenv("E2_TYPE1_LAB")) == NULL))
        type1 = bm_compile("(Type 1)");
    else
        type1 = bm_compile(x);
    if (((x = getenv("E2_TYPE2_LAB")) == NULL))
        type2 = bm_compile("(Type 2)");
    else
        type2 = bm_compile(x);
    if (((x = getenv("E2_TYPE3_LAB")) == NULL))
        type3 = bm_compile("(Type 3)");
    else
        type3 = bm_compile(x);
    if (((x = getenv("E2_TYPE4_LAB")) == NULL))
        type4 = bm_compile("(Type 4)");
    else
        type4 = bm_compile(x);
    if (((x = getenv("E2_TYPE1_THRESH")) == NULL)
      || (type1_thresh = strtod(x, NULL)) <= 0.0)
        type1_thresh = 2.0;
    if (((x = getenv("E2_TYPE2_THRESH")) == NULL)
      || (type2_thresh = strtod(x, NULL)) <= 0.0)
        type2_thresh = 7.0;
    if (((x = getenv("E2_TYPE3_THRESH")) == NULL)
      || (type3_thresh = strtod(x, NULL)) <= 0.0)
        type3_thresh = 10.0;
    if (((x = getenv("E2_TYPE4_THRESH")) == NULL)
      || (type4_thresh = strtod(x, NULL)) <= 0.0)
        type4_thresh = 10.0;
    if (((x = getenv("E2_UNSPEC_THRESH")) == NULL)
      || (unspec_thresh = strtod(x, NULL)) <= 0.0)
        unspec_thresh = 2.0;
    if ((type1_desc = getenv("E2_TYPE1_DESC")) == NULL)
        type1_desc = "NHS Type 1 (Application Server Only)";
    strncpy(sla[0].desc, type1_desc, sizeof(sla[0].desc));
    if ((type2_desc = getenv("E2_TYPE2_DESC")) == NULL)
        type2_desc = "NHS Type 2 (Database Server Read)";
    strncpy(sla[1].desc, type2_desc, sizeof(sla[1].desc));
    if ((type3_desc = getenv("E2_TYPE3_DESC")) == NULL)
        type3_desc = "NHS Type 3 (Database Server Write)";
    strncpy(sla[2].desc, type3_desc, sizeof(sla[2].desc));
    if ((type4_desc = getenv("E2_TYPE4_DESC")) == NULL)
        type4_desc = "NHS Type 4 (External System Communication)";
    strncpy(sla[3].desc, type4_desc, sizeof(sla[3].desc));
    strcpy(sla[4].desc, "Unspecified");
    for (i = 0; i < 6; i++)
    {
        sla[i].desc[sizeof(sla[0].desc) - 1] ='\0';
        sla[i].sla_class = i;
        sla[i].first_buc = &sla_bucs[i];
        sla[i].first_when = &sla_when[i];
    }
    strcpy(sla[5].desc, "Errors");
    sla[5].sla_class = 5;
    sla[5].first_buc = &sla_bucs[5];
/*
 * Process the Input Stream. The file should be ordered by:
 * PID, bundle, id, event order, but the program is highly tolerant of garbage.
 *
 * Whether or not distinct PID's should be processed separately or together
 * is controlled by the run options.
 */ 
    anchor = (struct collcon *) NULL;
    if (res_scope == PID)
        open_sess = hash(MAX_SESS,uhash_pid,ucomp_pid);
    else
    if (res_scope == BUNDLE)
        open_sess = hash(MAX_SESS,uhash_bun,ucomp_bun);
    else
        open_sess = hash(MAX_SESS,uhash_uni,ucomp_uni);
/*
 * Yes! C allows harmful goto's!
 */
again:
/*
 * If the user requested Web output, provide the web page header
 */
    if (off_flag == -1)
    {
        if ((html_head = getenv("html_head")) != NULL)
            fputs(html_head, out_fp);
        else
        fprintf(out_fp, "<html>\r\n<head>\r\n<style type=\"text/css\">\r\n\
body {\r\n\
    font-family: arial, geneva, helvetica, sans-serif;\r\n\
    font-size: 14px;\r\n\
    color: #000000;\r\n\
    line-height: 15px;\r\n\
}\r\n\
a {\r\n\
    font-family: arial, geneva, helvetica, sans-serif;\r\n\
    font-size: 8px;\r\n\
    color: #0000f0;\r\n\
    line-height: 15px;\r\n\
}\r\n\
h1 {\r\n\
        font-family: arial, geneva, helvetica, sans-serif;\r\n\
        color: 000000;\r\n\
        font-size: 18px;\r\n\
        font-weight: bold;\r\n\
        text-decoration: none; \r\n\
}\r\n\
.title {\r\n\
        font-family: arial, geneva, helvetica, sans-serif;\r\n\
        color: 000000;\r\n\
        font-size: 18px;\r\n\
        font-weight: bold;\r\n\
        text-decoration: none; \r\n\
}\r\n\
table {\r\n\
        font-family: arial, geneva, helvetica, sans-serif;\r\n\
        border-width: 1; \r\n\
        border-style: solid; \r\n\
        border-color: #a0a0a0; \r\n\
        background-color: #ffffff;\r\n\
        font-size: 14px;\r\n\
}\r\n\
</style>\r\n\
<script>\r\n\
function shoh(id) {   \r\n\
  if (document.getElementById(id)) { // DOM3 = IE5, NS6\r\n\
    if (document.getElementById(id).style.display == 'none'){\r\n\
      document.getElementById(id).style.display = 'block';\r\n\
    } else {\r\n\
      document.getElementById(id).style.display = 'none';      \r\n\
    }\r\n\
  } else {\r\n\
    if (document.layers) {  \r\n\
      if (document.id.display == 'none'){\r\n\
        document.id.display = 'block';\r\n\
      } else {\r\n\
        document.id.display = 'none';\r\n\
      }\r\n\
    } else {\r\n\
      if (document.all.id.style.visibility == 'hidden'){\r\n\
        document.all.id.style.visibility = 'visible';\r\n\
      } else {\r\n\
        document.all.id.style.visibility = 'hidden';\r\n\
      }\r\n\
    }\r\n\
  } \r\n\
}\r\n\
</script>\r\n\
<title>%s</title>\r\n</head>\r\n<body>\r\n\
<table width='100%%'><tbody>\n\
<tr>\n\
<td class='title'>%s</td>\n\
<td width='25%%' align='right'><A HREF='/'>\n\
<img\n\
src='data:image/gif;base64,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\n\
BnL1D3gjgZo5HyHUPgnNEN7ntRAAADs='\n\
 alt='E2 Systems Logo' /></A></td></tr>\n\
</tbody></table>\r\n", wtitle, wtitle);

        if (time_check == DO)
        {
            fprintf(out_fp, "<p>Timings collected between %s and ",
                                 ctime(&first_time));
            fprintf(out_fp, "%s</p>\r\n", ctime(&last_time));
        }
    }
    else
    if (time_check == DO && suppress_flag != -1)
    {
        fprintf(out_fp, "Timings collected between %s and ",
                                ctime(&first_time));
        fprintf(out_fp, "%s\n", ctime(&last_time));
    }
/*
 * Loop - process the input stream
 */
    tcon.cnt = 0;
    tcon.rs = NULL;
    tcon.tot = 0.0;
    tcon.tot2 = 0.0;
    tcon.min = 99999999;
    tcon.max  = 0.0;
    tcon.desc[0]  = '\0';
    last_pid[0] = '\0';
    last_bun = 0;
    if (incremental_flag)
    {
        fp = stdin;
        do_one_fp(fp, open_sess, res_scope, time_check, first_time,
              last_time, last_pid, &last_bun, &anchor,
              &tcon, &rs, &done_aborts, off_flag, realtime_flag, suppress_flag,
              sep_char);
    }
    else
    while (optind < argc || fp == (FILE *) NULL)
    {
        if (optind < argc)
        {
            if (!strcmp(argv[optind],"-"))
                fp = stdin;
            else
                fp = fopen(argv[optind],"rb");
            optind++;
        }
        else
        if (fp == (FILE *) NULL)
            fp = stdin;
        if (fp == (FILE *) NULL)
        {
            perror("fopen() failed");
            fprintf(stderr, "Failed to open %s\n", argv[optind]);
            break;
        }
        do_one_fp(fp, open_sess, res_scope, time_check, first_time,
              last_time, last_pid, &last_bun, &anchor,
              &tcon, &rs, &done_aborts, off_flag, realtime_flag, suppress_flag,
              sep_char);
        fclose(fp);
    }
    if (off_flag == -1 && done_aborts)
        fputs("</table></h1>\r\n", out_fp);
/*
 * Finished the file. Now output the results to stdout
 */
    if (res_scope != UNIVERSAL && !realtime_flag && suppress_flag != -1)
    {
#ifdef DEBUG
    fputs("Ready to Output Stream Summary\n", stderr);
        fflush(stderr);
#endif
        if (off_flag == -1)
        {
           if (!suppress_flag)
           {
               fputs("<h1>Transaction Stream Elapsed Times/Seconds</h1>\r\n\
    <table cellpadding='1' cellspacing='1' border='1'>\r\n\
    <tr><th>Transaction</th><th>Count</th><th>Avge Elapsed</th></tr>\r\n", out_fp);
                for (rs = run_anchor;
                         rs != (struct run_struct *) NULL;
                             rs = rs->next_run)
                {
                    for (bd = rs->first_bun;
                        bd != (struct bun_det *) NULL;
                            bd = bd->next_bun)
                    { 
                        if (bd->cnt > 0)
                        {
                            fputs("<tr><td>", out_fp);
                            if (res_scope == PID)
                                fprintf(out_fp, "%9.9s:",rs->pid);
                            fprintf(out_fp,  "%s</td><td>%5.1d</td><td>%15.2f</td><td></tr>\r\n",
                                        bd->tran,  bd->cnt,
                                       bd->elapsed/((double) bd->cnt));
                        }
                    }
                    if (res_scope != PID)
                        break;
                }
                fputs("</table>\r\n", out_fp);
            }
        }
        else
        {
            if (res_scope == PID)
                fputs("          ", out_fp);
            fputs( "Transaction Stream Elapsed Times/Second\n", out_fp);
            if (res_scope == PID)
                fputs("          ", out_fp);
            fputs("=============================\n", out_fp);
            if (res_scope == PID)
                fputs("          ", out_fp);
            fprintf(out_fp, "%-30.30s %-13.13s %5.5s %15.15s\n",
                     "Transaction","Seed","Count","Avge Elapsed");
            for (rs = run_anchor;
                     rs != (struct run_struct *) NULL;
                         rs = rs->next_run)
            {
                for (bd = rs->first_bun;
                    bd != (struct bun_det *) NULL;
                        bd = bd->next_bun)
                { 
                    if (bd->cnt > 0)
                    {
                        if (res_scope == PID)
                            fprintf(out_fp, "%9.9s:",rs->pid);
                        fprintf(out_fp,  "%-30.30s %-13.13s %5.1d %15.2f\n",
                                    bd->tran, bd->seed, bd->cnt,
                                   bd->elapsed/((double) bd->cnt));
                    }
                }
                if (res_scope != PID)
                    break;
            }
        }
    }
#ifdef DEBUG
    fprintf(stderr,"Ready to Output Timings\n");
    fflush(stderr);
#endif
    if (off_flag == -1)
    {
/*
 * Output graphs of SLA breaches.
 */
        fputs("<h1>SLA Pressure Points</h1>\r\n", out_fp);
        for (i = 0; i < 6; i++)
        {
            if ((x = do_slow_graph(&sla[i])) != NULL)
            {
#ifdef GENERATE_SVG
                fprintf(out_fp, "<iframe style=\"background-color:white;display:block;\" id=\"%s\" name=\"%s\" src=\"%s\" frameborder=\"0\" height=\"480\" width=\"640\"></iframe>\r\n", x, x, x);
#else
                fprintf(out_fp, "<img style=\"display:block;\" id=\"%s\" name=\"%s\" src=\"%s\" alt=\"%s\" />\r\n",
                        x,x,x,x);
#endif
            }
        }
        fputs("<h1>Response Time Summary/Seconds</h1>\r\n\
<table cellpadding='0' cellspacing='0' border='1'>\r\n\
<tr><th>Event Description</th><th>Count</th><th>Avge</th><th>SD</th>\r\n", out_fp);
        if (do_95 != 0.0)
            fprintf(out_fp, "<th>%.16g%%</th>\r\n", do_95 );
        fputs("<th>Min</th><th>10%</th><th>20%</th><th>30%</th><th>40%</th><th>50%</th><th>60%</th><th>70%</th><th>80%</th><th>90%</th><th>Max</th></tr>\r\n",
               out_fp);
    }
    else
    if (suppress_flag != -1)
    {
        fputs("Response Time Summary/Seconds\n", out_fp);
        fputs("=============================\n", out_fp);
        if (do_95 != 0.0)
            fprintf(out_fp, "%-44.44s%c%5.5s%c%5.5s%c%5.5s%c%.16g%%%c%5.5s%c%5.5s%c%5.5s%c\
%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s\n",
           "Event Description", sep_char,
           "Count", sep_char,
           "Avge", sep_char,
           "SD", sep_char,
            do_95, sep_char,
           "Min", sep_char,
           "10%",sep_char,
           "20%",sep_char,
           "30%",sep_char,
           "40%",sep_char,
           "50%",sep_char,
           "60%",sep_char,
           "70%",sep_char,
           "80%",sep_char,
           "90%",sep_char,
           "Max");
        else
            fprintf(out_fp, "%-44.44s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c\
%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s%c%5.5s\n",
               "Event Description", sep_char,
               "Count", sep_char,
               "Avge", sep_char,
               "SD", sep_char,
               "Min", sep_char,
               "10%",sep_char,
               "20%",sep_char,
               "30%",sep_char,
               "40%",sep_char,
               "50%",sep_char,
               "60%",sep_char,
               "70%",sep_char,
               "80%",sep_char,
               "90%",sep_char,
               "Max");
    }
    if (suppress_flag != -1)
    {
/*
 * To begin with, output the SLA Summary. These are not
 * chained together, so reverse_print() doesn't recurse.
 */
        for (i = 0; i < 6; i++)
            reverse_print(&sla[i], off_flag, do_95);
/*
 * Now output the details run by run
 */
        reverse_print(anchor, off_flag, do_95);
    if (off_flag == -1)
        {
            if (do_95 != 0.0)
            {
                fputs("</table>\r\n", out_fp);
                fputs("<h1>Response Time SLA Colour Key</h1>\r\n", out_fp);
        fprintf(out_fp, "<table><tr><th>Response Class</th><th>%.16g Percentile Below</th><th>Average Below</th><th><b>Average ABOVE</b></th><tr>\r\n", do_95);
                if (sla[0].cnt)
                    fprintf(out_fp, "<tr><td>%s</td><td style=\"background-color: #ffffff\">%.3f</td><td style=\"background-color: #ff8000\">%.3f</td><td style=\"background-color: #ff0000\">%.3f</td></tr>\r\n", type1_desc, type1_thresh, type1_thresh, type1_thresh);
                if (sla[1].cnt)
                    fprintf(out_fp, "<tr><td>%s</td><td style=\"background-color: #ffffff\">%.3f</td><td style=\"background-color: #ff8040\">%.3f</td><td style=\"background-color: #ff0040\">%.3f</td></tr>\r\n", type2_desc, type2_thresh, type2_thresh, type2_thresh);
                if (sla[2].cnt)
                    fprintf(out_fp, "<tr><td>%s</td><td style=\"background-color: #ffffff\">%.3f</td><td style=\"background-color: #ff8080\">%.3f</td><td style=\"background-color: #ff0080\">%.3f</td></tr>\r\n", type3_desc, type3_thresh, type3_thresh, type3_thresh);
                if (sla[3].cnt)
                    fprintf(out_fp, "<tr><td>%s</td><td style=\"background-color: #ffffff\">%.3f</td><td style=\"background-color: #ff80c0\">%.3f</td><td style=\"background-color: #ff00c0\">%.3f</td></tr>\r\n", type4_desc, type4_thresh, type4_thresh, type4_thresh);
                if (sla[4].cnt)
                    fprintf(out_fp, "<tr><td>Unspecified</td><td style=\"background-color: #ffffff\">%.3f</td><td style=\"background-color: #ff8000\">%.3f</td><td style=\"background-color: #ff0000\">%.3f</td></tr>\r\n", unspec_thresh, unspec_thresh, unspec_thresh);
            }
            if ((html_tail = getenv("html_tail")) != NULL)
                fputs(html_tail, out_fp);
            else
                fputs("</table>\r\n<A HREF='http://www.e2systems.co.uk/page003.html'>Brought to you by PATH from E2 Systems Limited - the UK's Leading Independent Performance and Volume Testers</A></body>\r\n</html>\r\n", out_fp);
    
        }
    }
/*
 * The support for Real-time monitoring requires we pause and continue.
 * A most harmful goto provides the needful.
 */
    if (incremental_flag)
    {
        fclose(out_fp);
        printf("%s\n", out_fname);
        fflush(stdout);
        g_seq = 0;           /* re-use graph names */
        done_aborts = 0;     /* reset headings     */
        if (fgets(last_pid, sizeof(last_pid), stdin) != NULL
          && (out_fp = fopen(out_fname, "wb")) != NULL)
            goto again;
    } 
    exit(0);
}
