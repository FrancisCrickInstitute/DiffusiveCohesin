#ifdef COMPUTE_CLASS
ComputeStyle(nearest/dna,ComputeNearestDNA)
#else

#ifndef LMP_COMPUTE_NEAREST_DNA_H
#define LMP_COMPUTE_NEAREST_DNA_H

#include "compute.h"

namespace LAMMPS_NS {

class ComputeNearestDNA : public Compute {
 public:
  ComputeNearestDNA(class LAMMPS *, int, char **);
  ~ComputeNearestDNA() override;

  void init() override;
  void compute_peratom() override;
  double memory_usage() override;

 protected:
  int groupbit_dna;
  int nmax;

  // NEW: user-tunable parameters
  int window_half;      // contour window half-width
  double r_switch;      // if best-in-window distance > r_switch -> do global search
  double r_detach;      // if best-global distance > r_detach -> report ID=0 (detached)

  int max_tag_seen;     // optional safety

};

}  // namespace LAMMPS_NS

#endif
#endif
