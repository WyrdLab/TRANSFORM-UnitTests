within TRANSFORMTest.Fluid.Machines;
model Pump_ZeroSpeed
  "With the Quadratic head curve a pump whose speed falls to zero becomes a flow resistance"
  extends TRANSFORM.Icons.Example;
  // Six pumps of 10 kg/s and 2 bar nominal, each between two fixed pressures 0.5 bar apart, run at
  // nominal speed to t = 1 s, slow to half speed by t = 2 s, hold it to t = 4 s, and stop at
  // t = 5 s. Quadratic, with its default shutoff head of twice the nominal head, gives
  //   head/head_nominal = 2*r_N*|r_N|*r_D^2 - m_rel*|m_rel|/r_D^4
  // (r_D = diameter/diameter_nominal). 0.5 bar is a quarter of dp_nominal, so m_rel solves this
  // with head/head_nominal = +0.25 (0.5 bar against the pump) or -0.25 (with it). The flows match
  // to within 4e-5, from regSquare's smoothing near zero flow (V_flow_small = 0.01*V_flow_nominal).
  //   m_rel_a: pumpA (Pump_Controlled, Machines family), against: sqrt(1.75) = 1.3229 at full
  //            speed, 0.5 at half speed, -0.5 stopped.
  //   m_rel_b: pumpB (Pump, ClosureRelations family), the same.
  //   m_rel_c: pumpC (Pump_Controlled), with (natural circulation): 1.5, sqrt(0.75) = 0.8660, +0.5.
  //   m_rel_d: pumpD (Pump_Controlled, r_D = 1.2), against: sqrt(2.63*1.2^4) = 2.3353,
  //            sqrt(0.47*1.2^4) = 0.9872, -sqrt(0.25*1.2^4) = -0.72.
  //   m_rel_e: pumpE (Pump, r_D = 1.2), the same.
  //   m_rel_f: pumpF (Pump_Controlled, checkValve = true, head_shutoff = 3*head_nominal, so
  //            head/head_nominal = 3*r_N^2 - 2*m_rel^2), against: sqrt(1.375) = 1.1726, 0.5, then
  //            0 once the speed term falls below the back pressure (r_N < sqrt(1/12), t = 4.42 s).
  //            Its valve closes after pumpB's flow has reversed (t = 4.29 s): a closing at that very
  //            instant made Dymola re-solve pumpB, which has no volume (V = 0), at exactly zero flow,
  //            where its enthalpy is undetermined, and the run stopped.
  // With the default PerformanceCurve of either family instead, the stopped pumps' flow grows
  // without bound (Dymola 2026x, pumps A, B, C: -1.5e7, -1.4e10 and +7.5e6 times nominal).
  replaceable package Medium = Modelica.Media.Water.StandardWater;
  parameter SI.Temperature T = 303.15 "Water temperature";
  parameter SI.MassFlowRate m_flow_nominal = 10 "Nominal flow of each pump";
  parameter SI.PressureDifference dp_nominal = 2e5 "Nominal pressure rise of each pump";
  parameter SI.Pressure p_low = 1e5 "Lower boundary pressure";
  parameter SI.Pressure p_high = 1.5e5 "Higher boundary pressure";
  parameter Modelica.Units.NonSI.AngularVelocity_rpm N_nominal = 1500 "Nominal speed";
  parameter Real r_D = 1.2 "Impeller diameter over nominal, pumps D and E";

  Modelica.Blocks.Sources.TimeTable speed(table=[0, N_nominal; 1, N_nominal; 2, 0.5*N_nominal;
    4, 0.5*N_nominal; 5, 0; 10, 0]) "Nominal speed, half speed, stop";
  TRANSFORM.Fluid.Machines.Pump_Controlled pumpA(redeclare package Medium = Medium,
    redeclare model FlowChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Flow.Quadratic,
    controlType="RPM", use_port=true, N_nominal=N_nominal, p_a_start=p_low,
    p_b_start=p_high, T_a_start=T, m_flow_start=m_flow_nominal, dp_nominal=dp_nominal)
    "Against 0.5 bar";
  TRANSFORM.Fluid.Machines.Pump pumpB(redeclare package Medium = Medium,
    redeclare model FlowChar =
      TRANSFORM.Fluid.ClosureRelations.PumpCharacteristics.Models.Head.Quadratic,
    controlType="RPM", use_port=true,
    N_nominal=N_nominal, p_a_start=p_low, p_b_start=p_high, T_start=T,
    m_flow_nominal=m_flow_nominal, dp_nominal=dp_nominal, m_flow_start=m_flow_nominal)
    "Against 0.5 bar";
  TRANSFORM.Fluid.Machines.Pump_Controlled pumpC(redeclare package Medium = Medium,
    redeclare model FlowChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Flow.Quadratic,
    controlType="RPM", use_port=true, N_nominal=N_nominal, p_a_start=p_high,
    p_b_start=p_low, T_a_start=T, m_flow_start=m_flow_nominal, dp_nominal=dp_nominal)
    "With 0.5 bar";
  TRANSFORM.Fluid.Machines.Pump_Controlled pumpD(redeclare package Medium = Medium,
    redeclare model FlowChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Flow.Quadratic,
    controlType="RPM", use_port=true, N_nominal=N_nominal, diameter=r_D*pumpD.diameter_nominal,
    p_a_start=p_low, p_b_start=p_high, T_a_start=T, m_flow_start=m_flow_nominal,
    dp_nominal=dp_nominal) "Larger impeller, against 0.5 bar";
  TRANSFORM.Fluid.Machines.Pump pumpE(redeclare package Medium = Medium,
    redeclare model FlowChar =
      TRANSFORM.Fluid.ClosureRelations.PumpCharacteristics.Models.Head.Quadratic,
    controlType="RPM", use_port=true, diameter=r_D*pumpE.diameter_nominal,
    N_nominal=N_nominal, p_a_start=p_low, p_b_start=p_high, T_start=T,
    m_flow_nominal=m_flow_nominal, dp_nominal=dp_nominal, m_flow_start=m_flow_nominal)
    "Larger impeller, against 0.5 bar";
  TRANSFORM.Fluid.Machines.Pump_Controlled pumpF(redeclare package Medium = Medium,
    redeclare model FlowChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Flow.Quadratic (
        checkValve=true, head_shutoff=3*pumpF.head_nominal),
    controlType="RPM", use_port=true, N_nominal=N_nominal, p_a_start=p_low,
    p_b_start=p_high, T_a_start=T, m_flow_start=m_flow_nominal, dp_nominal=dp_nominal)
    "Check valve, against 0.5 bar";
  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT low(redeclare package Medium = Medium,
    p=p_low, T=T, nPorts=6);
  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT high(redeclare package Medium = Medium,
    p=p_high, T=T, nPorts=6);
  Real m_rel_a = pumpA.port_a.m_flow/m_flow_nominal "Flow of pumpA over nominal";
  Real m_rel_b = pumpB.port_a.m_flow/m_flow_nominal "Flow of pumpB over nominal";
  Real m_rel_c = pumpC.port_a.m_flow/m_flow_nominal "Flow of pumpC over nominal";
  Real m_rel_d = pumpD.port_a.m_flow/m_flow_nominal "Flow of pumpD over nominal";
  Real m_rel_e = pumpE.port_a.m_flow/m_flow_nominal "Flow of pumpE over nominal";
  Real m_rel_f = pumpF.port_a.m_flow/m_flow_nominal "Flow of pumpF over nominal";
  TRANSFORM.Utilities.ErrorAnalysis.UnitTests unitTests(n=6, x={m_rel_a, m_rel_b, m_rel_c,
    m_rel_d, m_rel_e, m_rel_f})
    annotation (Placement(transformation(extent={{80,80},{100,100}})));
equation
  connect(speed.y, pumpA.inputSignal);
  connect(speed.y, pumpB.inputSignal);
  connect(speed.y, pumpC.inputSignal);
  connect(speed.y, pumpD.inputSignal);
  connect(speed.y, pumpE.inputSignal);
  connect(speed.y, pumpF.inputSignal);
  connect(low.ports[1], pumpA.port_a);
  connect(pumpA.port_b, high.ports[1]);
  connect(low.ports[2], pumpB.port_a);
  connect(pumpB.port_b, high.ports[2]);
  connect(high.ports[3], pumpC.port_a);
  connect(pumpC.port_b, low.ports[3]);
  connect(low.ports[4], pumpD.port_a);
  connect(pumpD.port_b, high.ports[4]);
  connect(low.ports[5], pumpE.port_a);
  connect(pumpE.port_b, high.ports[5]);
  connect(low.ports[6], pumpF.port_a);
  connect(pumpF.port_b, high.ports[6]);
  annotation (experiment(StopTime=10, __Dymola_Algorithm="Dassl"));
end Pump_ZeroSpeed;
