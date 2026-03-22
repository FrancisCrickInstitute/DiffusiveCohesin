/* ----------------------------------------------------------------------
   Custom Morse with dynamic contour window to enforce 1D sliding
   along a single DNA contour for one specific cohesin head.

   Strictly prevents "large jumps" by only updating the center
   to beads within the current topological window.
------------------------------------------------------------------------- */

#include "pair_morse_dynamic_window.h"
#include "atom.h"
#include "comm.h"
#include "error.h"
#include "force.h"
#include "memory.h"
#include "neigh_list.h"
#include "utils.h"
#include "neighbor.h"
#include "neigh_list.h"
#include <cmath>
#include <cstring>

using namespace LAMMPS_NS;
/* ---------------------------------------------------------------------- */

PairMorseDynamicWindow::PairMorseDynamicWindow(LAMMPS *lmp)
    : PairMorse(lmp)
{
  window_half_      = 0;
  right_head_tag_   = 0;
  prev_closest_tag_ = 0;
}

/* ---------------------------------------------------------------------- */

void PairMorseDynamicWindow::settings(int narg, char **arg)
{
  if (narg < 1 || narg > 3)
    error->all(FLERR, "Illegal pair_style morse/dynamic_window command");

  cut_global = utils::numeric(FLERR, arg[0], false, lmp);

  window_half_      = 0;
  right_head_tag_   = 0;
  prev_closest_tag_ = 0;

  if (narg >= 2) {
    double w = utils::numeric(FLERR, arg[1], false, lmp);
    if (w < 0.0)
      error->all(FLERR,
                 "pair_style morse/dynamic_window: window_half must be >= 0");
    window_half_ = static_cast<int>(w + 0.5);
  }

  if (narg >= 3) {
    right_head_tag_ = utils::tnumeric(FLERR, arg[2], false, lmp);
  }

  if (allocated) {
    for (int i = 1; i <= atom->ntypes; i++)
      for (int j = i; j <= atom->ntypes; j++)
        if (setflag[i][j]) cut[i][j] = cut_global;
  }
}

/* ---------------------------------------------------------------------- */

void PairMorseDynamicWindow::compute(int eflag, int vflag)
{
  int i, j, ii, jj, inum, jnum, itype, jtype;
  double xtmp, ytmp, ztmp, delx, dely, delz, evdwl, fpair;
  double rsq, r, dr, dexp, factor_lj;
  int *ilist, *jlist, *numneigh, **firstneigh;

  evdwl = 0.0;
  ev_init(eflag, vflag);

  double **x    = atom->x;
  double **f    = atom->f;
  int *type     = atom->type;
  tagint *tag   = atom->tag;
  int nlocal    = atom->nlocal;
  double *special_lj = force->special_lj;
  int newton_pair    = force->newton_pair;

  inum       = list->inum;
  ilist      = list->ilist;
  numneigh   = list->numneigh;
  firstneigh = list->firstneigh;


  tagint current_closest_tag = prev_closest_tag_;
  double min_rsquared        = 1.0e30;

  const bool window_active =
      (window_half_ > 0 && right_head_tag_ > 0 && prev_closest_tag_ > 0);

  // --------------------------------------------------
  // main loop
  // --------------------------------------------------

  for (ii = 0; ii < inum; ii++) {
    i    = ilist[ii];
    xtmp = x[i][0];
    ytmp = x[i][1];
    ztmp = x[i][2];
    itype = type[i];
    jlist = firstneigh[i];
    jnum  = numneigh[i];

    for (jj = 0; jj < jnum; jj++) {
      j         = jlist[jj];
      factor_lj = special_lj[sbmask(j)];
      j        &= NEIGHMASK;

      delx = xtmp - x[j][0];
      dely = ytmp - x[j][1];
      delz = ztmp - x[j][2];
      rsq  = delx * delx + dely * dely + delz * delz;
      jtype = type[j];

      if (rsq >= cutsq[itype][jtype]) continue;

      bool allow_morse = true;

      if (right_head_tag_ > 0) {
        tagint ti = tag[i];
        tagint tj = tag[j];

        bool has_head = (ti == right_head_tag_) || (tj == right_head_tag_);

        if (has_head) {
          tagint dna_tag = (ti == right_head_tag_) ? tj : ti;
          bool is_within_window = true;


          if (window_active) {
            tagint lo = prev_closest_tag_ - window_half_;
            tagint hi = prev_closest_tag_ + window_half_;
            if (dna_tag < lo || dna_tag > hi) {
              allow_morse = false;
              is_within_window = false;
            }
          }

          if (is_within_window && rsq < min_rsquared) {
            min_rsquared        = rsq;
            current_closest_tag = dna_tag;
          }
        }
      }

      if (!allow_morse) continue;

      // -----------------------------
      // normal morse
      // -----------------------------

      r    = sqrt(rsq);
      dr   = r - r0[itype][jtype];
      dexp = exp(-alpha[itype][jtype] * dr);
      fpair = factor_lj * morse1[itype][jtype] * (dexp * dexp - dexp) / r;

      f[i][0] += delx * fpair;
      f[i][1] += dely * fpair;
      f[i][2] += delz * fpair;
      if (newton_pair || j < nlocal) {
        f[j][0] -= delx * fpair;
        f[j][1] -= dely * fpair;
        f[j][2] -= delz * fpair;
      }

      if (eflag) {
        evdwl = d0[itype][jtype] * (dexp * dexp - 2.0 * dexp) -
                offset[itype][jtype];
        evdwl *= factor_lj;
      }

      if (evflag)
        ev_tally(i, j, nlocal, newton_pair, evdwl, 0.0, fpair,
                 delx, dely, delz);
    }
  }

  if (vflag_fdotr) virial_fdotr_compute();

  // --------------------------------------------------
  // prev_closest_tag_
  // --------------------------------------------------
  if (current_closest_tag > 0 &&
      current_closest_tag != prev_closest_tag_) {
    prev_closest_tag_ = current_closest_tag;
  }
}
