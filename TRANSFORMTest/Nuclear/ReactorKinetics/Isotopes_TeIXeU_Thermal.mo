within TRANSFORMTest.Nuclear.ReactorKinetics;
model Isotopes_TeIXeU_Thermal
  "The Te-I-Xe isotope record must give thermal-reactor physics: U-235 use per fission, flux and xenon worth"
  extends TRANSFORM.Icons.Example;
  // SparseMatrix point kinetics at a specified 25 MW with the Te-135 -> I-135 -> Xe-135 record
  // Isotopes_TeIXeU. The model takes the flux from the power and the U-235 fission cross-section,
  // and applies every other cross-section to that flux, so the record's values must belong to one
  // neutron spectrum.
  //   consumedPerFission: U-235 atoms used per fission in kU (1000 kg, depleting), counted from the
  //       atoms lost and the fissions the power implies. Thermal U-235 loses (sigma_f + sigma_c)/
  //       sigma_f = 1 + alpha, about 1.17 atoms per fission. On TRANSFORM 1.3.0 the record mixed a
  //       fast fission value (1.218 b) with an absorption of 6.37 b (set in 2021, no reason
  //       recorded): 5.23.
  //   dRhoXe: kXe (5.2 kg, U-235 held constant, so the flux is constant) at xenon equilibrium,
  //       against the closed form rho = -(gamma/nu)*sigma_Xe*phi/(lambda_Xe + sigma_Xe*phi), where
  //       gamma is the record's Te + Xe yield per fission; ratio - 1, 0 when right. Its magnitude can
  //       never exceed gamma/nu, about 2.6 %; at this flux xenon is near saturation, about -2.4 %.
  //       On TRANSFORM 1.3.0 production used the absorption cross-section (698.9 b) against
  //       fission 1.218 b: about -1530 % worth.
  // Also tracked (test_spec "variables"), checked absolutely so a self-consistent fast set fails too:
  //   kXe.reactivity.phi: 25 MW from 5.2 kg at 200 MeV per fission and thermal U-235 fission
  //       (about 587 b) gives about 1.0e18 n/(m2 s); a fast set gives about 480 times more.
  //   kXe.reactivity.rhos[3]: equilibrium xenon worth, about -2.44 % (bounded by -gamma/nu = -2.6 %).
  parameter SI.Power Q = 25e6 "Fission power of both";
  parameter SI.Mass m_U = 1000 "U-235 in kU";
  parameter SI.Mass m_U_Xe = 5.2 "U-235 in kXe (flux about 1e14 n/cm2/s with the thermal set)";
  final parameter Real N_U0 = m_U/kU.reactivity.data.molarMass[4]*Modelica.Constants.N_A
    "U-235 atoms at the start, kU";
  final parameter Real N_U0_Xe = m_U_Xe/kXe.reactivity.data.molarMass[4]*Modelica.Constants.N_A
    "U-235 atoms, kXe";

  TRANSFORM.Nuclear.ReactorKinetics.SparseMatrix.PointKinetics_L1_powerBased_sparseMatrix kU(
    Q_nominal=Q, specifyPower=true,
    redeclare record Data =
        TRANSFORM.Nuclear.ReactorKinetics.Data.PrecursorGroups.precursorGroups_6_TRACEdefault,
    toggle_Reactivity=true,
    redeclare model Reactivity =
        TRANSFORM.Nuclear.ReactorKinetics.SparseMatrix.Reactivity.Isotopes.Lumped.Isotopes_sparseMatrix (
        redeclare record Data =
            TRANSFORM.Nuclear.ReactorKinetics.SparseMatrix.Data.Isotopes.Isotopes_TeIXeU,
        mCs_start={0, 0, 0, N_U0})) "U-235 depletes";
  TRANSFORM.Nuclear.ReactorKinetics.SparseMatrix.PointKinetics_L1_powerBased_sparseMatrix kXe(
    Q_nominal=Q, specifyPower=true,
    redeclare record Data =
        TRANSFORM.Nuclear.ReactorKinetics.Data.PrecursorGroups.precursorGroups_6_TRACEdefault,
    toggle_Reactivity=true,
    redeclare model Reactivity =
        TRANSFORM.Nuclear.ReactorKinetics.SparseMatrix.Reactivity.Isotopes.Lumped.Isotopes_sparseMatrix (
        redeclare record Data =
            TRANSFORM.Nuclear.ReactorKinetics.SparseMatrix.Data.Isotopes.Isotopes_TeIXeU,
        mCs_start={0, 0, 0, N_U0_Xe}, use_noGen=true)) "U-235 held constant";

  Real nFissions(start=0, fixed=true) "Fissions so far in kU";
  Real consumedPerFission = (N_U0 - kU.reactivity.mCs[4])/max(nFissions, 1)
    "U-235 atoms used per fission, kU";
  Real rhoXe_expected = -(0.061 + 0.003)/kXe.reactivity.data.nus[1]
      *kXe.reactivity.data.sigmasA[3]*kXe.reactivity.phi/(kXe.reactivity.data.lambdas[3]
       + kXe.reactivity.data.sigmasA[3]*kXe.reactivity.phi)
    "Equilibrium xenon worth from the yields per fission (Te 0.061 + Xe 0.003) and nu";
  Real dRhoXe = kXe.reactivity.rhos[3]/rhoXe_expected - 1 "Xenon worth against the closed form";
  TRANSFORM.Utilities.ErrorAnalysis.UnitTests unitTests(n=2, x={consumedPerFission, dRhoXe})
    annotation (Placement(transformation(extent={{80,80},{100,100}})));
equation
  der(nFissions) = kU.Q_fission/kU.reactivity.data.w_f[1];
  annotation (experiment(StopTime=31536000, __Dymola_NumberOfIntervals=365,
        __Dymola_Algorithm="Esdirk45a"));
end Isotopes_TeIXeU_Thermal;
