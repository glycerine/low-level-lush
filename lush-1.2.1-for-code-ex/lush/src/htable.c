/***********************************************************************
 * 
 *  LUSH Lisp Universal Shell
 *    Copyright (C) 2002 Leon Bottou, Yann Le Cun, AT&T Corp, NECI.
 *  Includes parts of TL3:
 *    Copyright (C) 1987-1999 Leon Bottou and Neuristique.
 *  Includes selected parts of SN3.2:
 *    Copyright (C) 1991-2001 AT&T Corp.
 * 
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA
 * 
 ***********************************************************************/

/***********************************************************************
 * $Id: htable.c,v 1.14 2006/11/07 20:58:34 leonb Exp $
 **********************************************************************/

/***********************************************************************
  This file contains functions for handling hash tables
********************************************************************** */

/* --- INITIALISATION SECTION --- */

#include "header.h"


struct hashelt
{
  struct hashelt *next;
  unsigned long hash;
  at *key;
  at *value;
};

struct hashtable
{
  int   size;
  int   nelems;
  int   pointerhashp;
  int   keylockp;
  int   rehashp;
  struct hashelt **table;
};



/* --- PRIMITIVE SECTION --- */



/* alloc_hashelt -- structure for allocating hash nodes */

static struct alloc_root alloc_hashelt = {
  NULL,
  NULL,
  sizeof(struct hashelt),
  1000,
};


/* HASHTABLE CLASS FUNCTIONS */

static void 
htable_dispose(at *p)
{
  int i;
  struct hashelt *n, *m;
  struct hashtable *htable = p->Object;

  if (htable->pointerhashp)
    del_finalizers(htable);
  
  for (i=0; i<htable->size; i++)
    {
      n=htable->table[i];
      while(n)
        {
          m = n->next;
          if (htable->keylockp)
            UNLOCK(n->key);
          UNLOCK(n->value);
          deallocate(&alloc_hashelt,(void*)n);
          n = m;
        }
    }
  free(htable->table);
  free(htable);
  p->Object = NIL;
}


static void 
htable_action(at *p, void (*action)(at *))
{
  int i;
  struct hashelt *n;
  struct hashtable *htable = p->Object;
  for (i=0; i<htable->size; i++)
    for (n=htable->table[i]; n; n=n->next)
      {
        if (htable->keylockp)
          (*action)(n->key);
        (*action)(n->value);
      }
}


static at *
htable_listeval(at *p, at *q)
{
  q = q->Cdr;
  if ((!CONSP(q)) ||
      (q->Cdr && ((!CONSP(q->Cdr)) || q->Cdr->Cdr)))
    error(NIL,"One or two arguments expected",q);
  q = eval_a_list(q);
  if (q->Cdr)
    {
      htable_set(p,q->Car,q->Cdr->Car);
      LOCK(p);
      UNLOCK(q);
      return p;
    }
  else
    {
      p = htable_get(p,q->Car);
      UNLOCK(q);
      return p;
    }
}


static void
htable_serialize(at **pp, int code)
{
  if (code == SRZ_READ)
    {
      int nelems, i;
      struct hashelt *n;
      struct hashtable *htable;
      serialize_int(&i, code);
      serialize_int(&nelems, code);
      (*pp) = new_htable(nelems, i);
      htable = (*pp)->Object;
      htable->rehashp = 1;
      htable->keylockp = 1;
      for (i=0; i<nelems; i++)
        {
          n = allocate(&alloc_hashelt);
          n->hash = 0;
          n->next = htable->table[0];
          serialize_atstar(&n->key, code);
          serialize_atstar(&n->value, code);
          htable->table[0] = n;
          htable->nelems++;
        }
    }
  else
    {
      int i;
      struct hashelt *n;
      struct hashtable *htable = (*pp)->Object;
      i = htable->pointerhashp;
      serialize_int(&i, code);
      i = htable->nelems;
      serialize_int(&i, code);
      for (i=0; i<htable->size; i++)
        for (n=htable->table[i]; n; n=n->next) {
          serialize_atstar(&n->key, code);
          serialize_atstar(&n->value, code);
        }
    }
}


static int
htable_compare(at *p, at *q, int order)
{
  int i, c;
  at *val;
  struct hashelt *n;
  struct hashtable *htable = p->Object;
  struct hashtable *htable2 = q->Object;
  if (order)
    error(NIL,"Cannot rank hashtables",NIL);
  /* check number of elements */
  if (htable->nelems != htable2->nelems)
    return 1;
  /* check elements */
  for (i=0; i<htable->size; i++)
    for (n=htable->table[i]; n; n=n->next)
    {
      val = htable_get(q, n->key);
      if (!val)
        return 1;
      c = eq_test(val,n->value);
      UNLOCK(val);
      if (!c)
        return 1;
    }
  return 0;
}


static unsigned long
htable_hash(at *p)
{
  int i;
  unsigned long x = 0;
  struct hashelt *n;
  struct hashtable *htable = p->Object;
  for (i=0; i<htable->size; i++)
    for (n=htable->table[i]; n; n=n->next)
      {
        unsigned long y = hash_value(n->key);
        y = (y<<6) ^ hash_value(n->value);
        x ^= y;  /* hash code is order independent */
      }
  return x;
}


class htable_class =
{
  htable_dispose,
  htable_action,
  generic_name,
  generic_eval,
  htable_listeval,
  htable_serialize,
  htable_compare,
  htable_hash
};



/* HASHTABLE UTILITIES */


/* hash_pointer -- hash pointer bits */

unsigned long 
hash_pointer(at *p)
{
  unsigned long x = (unsigned long)p;
  x = x ^ (x>>16);
  return x;
}



/* hash_value -- hash object pointed to by p */

unsigned long 
hash_value(at *p)
{
  unsigned long x = 0;
  struct recur_elt elt;
  char toggle = 0;
  at *slow = p;

again:
  x = (x<<1)|((x&0x80000000) ? 0 : 1);
  if (!p)
    {
      return x;
    }
  else if (p->flags & C_NUMBER)
    {
      unsigned int *up = (unsigned int*)(char*)&p->Number;
      x ^= 0x1010;
      x ^= up[0];
      if (sizeof(real) >= 2*sizeof(unsigned int))
        x ^= up[1];
    }
  else if (p->flags & C_CONS)
    {
      x ^= 0x2020;
      if (recur_push_ok(&elt, &hash_value, p->Car))
        {
          x ^= hash_value(p->Car);
          recur_pop(&elt);
        }
      /* go to next list element */
      p = p->Cdr;
      if (p == slow) /* circular list */
        return x;
      toggle ^= 1;
      if (!toggle)
        slow = slow->Cdr;
      goto again;
    }
  else if ((p->flags & C_EXTERN) && (p->Class->hash))
    {
      x ^= 0x3030;
      if (recur_push_ok(&elt, &hash_pointer, p))
        {
          x ^= (*p->Class->hash)(p);
          recur_pop(&elt);
        }
    }
  else if (p->flags & C_GPTR)
    {
      x ^= 0x4040;
      x ^= (unsigned long)(p->Gptr);
    }
  else
    {
      x ^= hash_pointer(p);
    }
  return x;
}


/* htable_resize -- extend hash table */

static void 
htable_resize(struct hashtable *htable, int newsize)
{
  int i, j;
  struct hashelt *n, *m;
  struct hashelt **newtable;
  /* allocate newtable */
  newtable = malloc(sizeof(struct hashelt*) * newsize);
  if (!newtable)
    error(NIL,"Out of memory",NIL);
  for (i=0; i<newsize; i++)
    newtable[i] = 0;
  /* relocate hashelt */
  for (i=0; i<htable->size; i++)
    {
      n = htable->table[i];
      while (n)
        {
          m = n->next;
          j = n->hash % newsize;
          n->next = newtable[j];
          newtable[j] = n;
          n = m;
        }
    }
  /* free and replace */
  free(htable->table);
  htable->table = newtable;
  htable->size = newsize;
}



/* hashelt_finalizer -- helper for pointerhashp case */

static void
hashelt_finalize(at *k, void *table)
{
  struct hashtable *htable = table;
  struct hashelt **np, *n;
  unsigned long hash;
  
  hash = hash_pointer(k);
  np = &(htable->table[hash % htable->size]);
  while (*np)
    {
      n = *np;
      if (n->key != k)
        {
          np = &(n->next);
        }
      else
        {
          *np = n->next;
          UNLOCK(n->value);
          deallocate(&alloc_hashelt,(struct empty_alloc*)n);
          htable->nelems -= 1;
        }
    }
}

/* htable_rehash -- rehash an existing hash table */

static void 
htable_rehash(struct hashtable *htable)
{
  int i;
  int pointerhashp;
  struct hashelt *n, **np;
  pointerhashp = htable->pointerhashp;
  /* turn off keylockp when pointerhashp is true */
  if (pointerhashp && htable->keylockp)
    {
      at *p = NIL;
      for (i=0; i<htable->size; i++)
        for (n=htable->table[i]; n; n=n->next)
          {
            p = cons(n->key, p); /* steal lock */
            add_finalizer(p, hashelt_finalize, htable);
          }
      htable->keylockp = 0;
      UNLOCK(p);
    }
  /* recompute hash numbers */
  for (i=0; i<htable->size; i++)
    {
      np = &htable->table[i];
      while ((n = *np))
        {
          /* zap zombies */
          if ( (n->key && (n->key->flags & X_ZOMBIE)) ||
               (n->value && (n->value->flags & X_ZOMBIE)) )
            {
              *np = n->next;
              UNLOCK(n->key);
              UNLOCK(n->value);
              deallocate(&alloc_hashelt,(void*)n);
              htable->nelems -= 1;
              continue;
            }
          /* recompute hash */
          if (pointerhashp)
            n->hash = hash_pointer(n->key);
          else
            n->hash = hash_value(n->key);
          np = &(n->next);
        }
    }
  /* reorganize hash table */
  htable_resize(htable, htable->size);
  htable->rehashp = FALSE;
}



/* HASHTABLE ACCESS FUNCTIONS */


/* htable_set -- set element by key */

LUSHAPI void 
htable_set(at *ht, at *key, at *value)
{
  int i;
  unsigned long hash;
  struct hashelt *n,**np;
  struct hashtable *htable;
  int pointerhashp;
  
  if (!EXTERNP(ht, &htable_class))
    error(NIL,"not a hash table", ht);
  if ( value && (value->flags & X_ZOMBIE))
    value = NIL;
  if ( key && (key->flags & X_ZOMBIE))
    return;
  /* check hash table */
  htable = ht->Object;
  if (htable->rehashp)
    htable_rehash(htable);
  /* hash */
  pointerhashp = htable->pointerhashp;
  if (pointerhashp)
    hash = hash_pointer(key);
  else
    hash = hash_value(key);
  /* search */
  np = &(htable->table[hash % htable->size]);
  while ((n = *np))
    {
      if (key == n->key)
        break;
      if (!pointerhashp)
        if (hash == n->hash)
          if (eq_test(key, n->key))
            break;
      np = &(n->next);
    }
  /* change */
  if (value && n)
    {
      LOCK(value);
      UNLOCK(n->value);
      n->value = value;
    }
  else if (value)
    {
      while (2 * htable->size < 3 * htable->nelems)
        htable_resize(htable, 2 * htable->size - 1);
      n = allocate(&alloc_hashelt);
      if (!htable->keylockp)
        add_finalizer(key, hashelt_finalize, htable);
      else
        LOCK(key);
      LOCK(value);
      n->hash = hash;
      n->value = value;
      n->key = key;
      i = hash % htable->size;
      n->next = htable->table[i];
      htable->table[i] = n;
      htable->nelems += 1;
    }
  else if (n)
    {
      *np = n->next;
      if (htable->keylockp)
        UNLOCK(n->key);
      UNLOCK(n->value);
      deallocate(&alloc_hashelt,(void*)n);
      htable->nelems -= 1;
    }
}


/* htable_get -- get element by key */

LUSHAPI at *
htable_get(at *ht, at *key)
{
  struct hashelt *n, **np;
  struct hashtable *htable;
  unsigned long hash;
  int pointerhashp;

  if (!EXTERNP(ht, &htable_class))
    error(NIL,"not a hash table", ht);
  /* check hash table */
  htable = ht->Object;
  if (htable->rehashp)
    htable_rehash(htable);
  /* hash */
  pointerhashp = htable->pointerhashp;
  if (pointerhashp)
    hash = hash_pointer(key);
  else
    hash = hash_value(key);
  /* search chain */
  np = &htable->table[hash % htable->size];
  while ((n = *np))
    {
      if (key == n->key)
        break;
      if (!pointerhashp)
        if (hash == n->hash)
          if (eq_test(key, n->key))
            break;
      np = &(n->next);
    }
  if (n)
    {
      LOCK(n->value);
      return n->value;
    }
  return NIL;
}



/* HASHTABLE OPERATIONS */

/* hashcode */

DX(xhashcode)
{
  char buffer[24];
  unsigned long x;
  ARG_NUMBER(1);
  ARG_EVAL(1);
  x = hash_value(APOINTER(1));
  sprintf(buffer,"%08x", (int)(x));
  return new_string(buffer);
}


/* new_htable -- hashtable creation */

LUSHAPI at *
new_htable(int nelems, int pointerhashp)
{ 
  int i;
  int size;
  struct hashtable *htable;
  struct hashelt **table;
  size = (nelems<16 ? 31 : nelems * 2 - 1);
  table = malloc(size*sizeof(struct hashelt*));
  ifn (table)
    error(NIL,"Out of memory",NIL);
  htable = malloc(sizeof(struct hashtable));
  ifn (htable)
    error(NIL,"Out of memory",NIL);
  for (i=0; i<size; i++)
    table[i] = NIL;
  htable->nelems = 0;
  htable->size = size;
  htable->pointerhashp = pointerhashp;
  htable->keylockp = !pointerhashp;
  htable->rehashp = FALSE;
  htable->table = table;
  return new_extern(&htable_class,htable);
}

DX(xnew_htable)
{
  int nelems = 0;
  int pointerhashp = 0;

  ALL_ARGS_EVAL;
  if (arg_number>=1)
    nelems = AINTEGER(1);
  if (arg_number>=2)
    pointerhashp = (APOINTER(2) ? 1 : 0);
  if (arg_number>2)
    error(NIL,"At most two arguments expected",NIL);
  return new_htable(nelems,pointerhashp);
}



/* htable_alist -- returns contents as an alist */

DX(xhtable_alist)
{
  int i;
  at *ans;
  struct hashtable *htable;
  struct hashelt *n;
  ARG_NUMBER(1);
  ARG_EVAL(1);
  ans = APOINTER(1);
  if (!EXTERNP(ans, &htable_class))
    error(NIL,"not a hash table", ans);
  htable = ans->Object;
  ans = NIL;
  for (i=0; i<htable->size; i++)
    for (n=htable->table[i]; n; n=n->next)
      ans = cons(new_cons(n->key, n->value),ans);
  return ans;
}


/* htable_keys -- returns list of keys */

DX(xhtable_keys)
{
  int i;
  at *ans;
  struct hashtable *htable;
  struct hashelt *n;
  ARG_NUMBER(1);
  ARG_EVAL(1);
  ans = APOINTER(1);
  if (!EXTERNP(ans, &htable_class))
    error(NIL,"not a hash table", ans);
  htable = ans->Object;
  ans = NIL;
  for (i=0; i<htable->size; i++)
    for (n=htable->table[i]; n; n=n->next)
    {
      LOCK(n->key);
      ans = cons(n->key,ans);
    }
  return ans;
}




/* htable_rehash -- recompute hash numbers */

DX(xhtable_rehash)
{
  at *p;
  struct hashtable *htable;
  /* Get hash table */
  ARG_NUMBER(1);
  ARG_EVAL(1);
  p = APOINTER(1);
  if (!EXTERNP(p, &htable_class))
    error(NIL,"Not a hash table", p);
  htable = p->Object;
  htable->rehashp = TRUE;
  return NEW_NUMBER(htable->nelems);
}




/* htable_size -- returns htable number of elements */

DX(xhtable_size)
{
  at *p;
  struct hashtable *htable;
  ARG_NUMBER(1);
  ARG_EVAL(1);
  p = APOINTER(1);
  if (!EXTERNP(p, &htable_class))
    error(NIL,"Not a hash table", p);
  htable = p->Object;
  return NEW_NUMBER(htable->nelems);
}




/* htable_info -- return hashtable statistics */

#define MAXHITDEPTH 32

DX(xhtable_info)
{
  at *ans;
  struct hashtable *htable;
  struct hashelt *n;
  int hit[MAXHITDEPTH];
  int i,j,maxhit;
  /* Get hash table */
  ARG_NUMBER(1);
  ARG_EVAL(1);
  ans = APOINTER(1);
  if (!EXTERNP(ans, &htable_class))
    error(NIL,"Not a hash table", ans);
  htable = ans->Object;
  if (htable->rehashp)
    htable_rehash(htable);
  /* Initialize */
  maxhit = -1;
  for (j=0; j<MAXHITDEPTH; j++)
    hit[j] = 0;
  /* Iterate and count */
  for (i=0; i<htable->size; i++)
    for (n=htable->table[i],j=0; n; n=n->next,j++)
    {
      if (j<MAXHITDEPTH)
        hit[j] += 1;
      if (j>maxhit)
        maxhit = j;
    }
  /* Build result */
  ans = NIL;
  if (maxhit>=MAXHITDEPTH)
    ans = cons(cons(NEW_NUMBER(maxhit),NIL),NIL);
  for (j=MAXHITDEPTH-1; j>=0; j--)
    if (hit[j]) break;
  for (;j>=0; j--)
    ans = cons(NEW_NUMBER(hit[j]),ans);
  ans = cons(cons(named("hits"),ans),NIL);
  ans = cons(cons(named("buckets"),NEW_NUMBER(htable->size)),ans);
  ans = cons(cons(named("size"),NEW_NUMBER(htable->nelems)),ans);
  return ans;
}





/* --- INITIALISATION SECTION --- */

void init_htable(void)
{
  class_define("HTABLE",&htable_class);
  dx_define("hashcode",xhashcode);
  dx_define("htable",xnew_htable);
  dx_define("htable-alist",xhtable_alist);
  dx_define("htable-keys", xhtable_keys);
  dx_define("htable-rehash", xhtable_rehash);
  dx_define("htable-size",xhtable_size);
  dx_define("htable-info",xhtable_info);
}

