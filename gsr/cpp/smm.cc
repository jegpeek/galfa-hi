/* This is a code intended to be the C brains behind the IDL code sdgrid.pro */
/* It relies upon BLAS routines, from NIST */
/* J.E.G. Peek, July 2006*/

#include "stdio.h"
#include "blas_sparse.h"
#include "idl_export.h"

void smm(int argc, char* argv[]) {

  int M = (int) *(IDL_LONG*) argv[0];
  int N = (int) *(IDL_LONG*) argv[1];
  int nrhs = (int) *(IDL_LONG*) argv[2];
  int nels = (int) *(IDL_LONG*) argv[3];
  int* pCol = (int*) argv[4];
  int* pRow = (int*) argv[5];
  float* pVal = (float*) argv[6];
  float* pB = (float*) argv[7];
  float* pC = (float*) argv[8];

  blas_sparse_matrix A;
  int i;
  int out;
  double alpha = 1.0; 
  
  /* creating a sparse BLAS Handle */

  A = BLAS_suscr_begin(M, N);

    /* insert entries */

  for (i=0; i<nels; i++)
    BLAS_suscr_insert_entry(A, pVal[i], pCol[i], pRow[i]); 

  /* finish inserting entries */

  BLAS_suscr_end(A);

  /* multiply */

  out = BLAS_susmm( blas_colmajor,blas_no_trans, nrhs, alpha, A, pB, N, pC, M); 
  
  /* destroy */

  BLAS_usds(A);

}
