#include <cmath>
#include <algorithm>

#include "compute_nearest_dna.h"
#include "atom.h"
#include "domain.h"
#include "error.h"
#include "group.h"
#include "memory.h"
#include "update.h"

using namespace LAMMPS_NS;

ComputeNearestDNA::ComputeNearestDNA(LAMMPS *lmp, int narg, char **arg) :
  Compute(lmp, narg, arg)
{
  // Syntax (backward compatible):
  //   compute ID group-ID nearest/dna dna-group
  // or (recommended):
  //   compute ID group-ID nearest/dna dna-group WINHALF R_SWITCH R_DETACH
  //
  // Example:
  //   compute nearL leftHead nearest/dna dna 10 2.5 6.0

  if (narg != 4 && narg != 7)
    error->all(FLERR,"Illegal compute nearest/dna command. Use: compute ID group nearest/dna dnaGroup [winHalf rSwitch rDetach]");

  peratom_flag      = 1;
  size_peratom_cols = 2;

  nmax       = 0;
  array_atom = nullptr;

  int igroup_dna = group->find(arg[3]);
  if (igroup_dna == -1)
    error->all(FLERR,"Compute nearest/dna: DNA group ID does not exist");
  groupbit_dna = group->bitmask[igroup_dna];

  // defaults (safe-ish)
  window_half = 10;
  r_switch    = 2.5;
  r_detach    = 6.0;

  if (narg == 7) {
    window_half = std::max(0, atoi(arg[4]));
    r_switch    = atof(arg[5]);
    r_detach    = atof(arg[6]);
    if (r_switch <= 0.0 || r_detach <= 0.0 || r_detach < r_switch)
      error->all(FLERR,"Compute nearest/dna: require 0 < r_switch <= r_detach");
  }

  max_tag_seen = 0;
}

ComputeNearestDNA::~ComputeNearestDNA()
{
  memory->destroy(array_atom);
}

void ComputeNearestDNA::init() {}

void ComputeNearestDNA::compute_peratom()
{
  invoked_peratom = update->ntimestep;

  if (atom->nmax > nmax) {
    nmax = atom->nmax;
    memory->destroy(array_atom);
    memory->create(array_atom, nmax, size_peratom_cols, "nearest/dna:array_atom");
    for (int i = 0; i < nmax; i++) {
      array_atom[i][0] = 0.0;  // last nearest ID
      array_atom[i][1] = 0.0;  // last distance
    }
  }

  double **x   = atom->x;
  int    *mask = atom->mask;
  tagint *tag  = atom->tag;

  int nlocal = atom->nlocal;
  int nall   = nlocal + atom->nghost;

  // record max tag (optional sanity; cheap)
  for (int j = 0; j < nall; j++) max_tag_seen = std::max<int>(max_tag_seen, (int)tag[j]);

  for (int i = 0; i < nlocal; i++) {
    if (!(mask[i] & groupbit)) continue;

    const double xi = x[i][0];
    const double yi = x[i][1];
    const double zi = x[i][2];

    tagint last_id = 0;
    if (array_atom[i][0] > 0.5) last_id = static_cast<tagint>(array_atom[i][0] + 0.5);

    auto search = [&](bool use_window, double &best_d2, tagint &best_id) {
      best_d2 = 1.0e60;
      best_id = 0;

      for (int j = 0; j < nall; j++) {
        if (!(mask[j] & groupbit_dna)) continue;

        if (use_window && last_id > 0) {
          tagint tj = tag[j];
          if (tj < last_id - window_half || tj > last_id + window_half) continue;
        }

        double dx = xi - x[j][0];
        double dy = yi - x[j][1];
        double dz = zi - x[j][2];
        domain->minimum_image(FLERR, dx, dy, dz);

        double d2 = dx*dx + dy*dy + dz*dz;
        if (d2 < best_d2) {
          best_d2 = d2;
          best_id = tag[j];
        }
      }
    };

    double best_d2 = 1.0e60;
    tagint best_id = 0;

    // 1) window search (if have history)
    if (last_id > 0 && window_half > 0) {
      search(true, best_d2, best_id);

      // if window result is "too far", window tracking failed -> global search
      if (best_id > 0 && std::sqrt(best_d2) > r_switch) {
        search(false, best_d2, best_id);
      }
    } else {
      // no history -> global
      search(false, best_d2, best_id);
    }

    if (best_id > 0) {
      double dist = std::sqrt(best_d2);

      // if even global nearest is far -> detached
      if (dist > r_detach) {
        array_atom[i][0] = 0.0;
        array_atom[i][1] = dist;   // keep distance for diagnostics
      } else {
        array_atom[i][0] = static_cast<double>(best_id);
        array_atom[i][1] = dist;
      }
    } else {
      array_atom[i][0] = 0.0;
      array_atom[i][1] = 0.0;
    }
  }
}

double ComputeNearestDNA::memory_usage()
{
  return (double)nmax * (double)size_peratom_cols * sizeof(double);
}
