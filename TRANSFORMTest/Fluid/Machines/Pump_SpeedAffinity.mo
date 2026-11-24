within TRANSFORMTest.Fluid.Machines;
model Pump_SpeedAffinity
  "Pump_Controlled at half speed must follow the affinity laws: flow ~ N, head ~ N^2, power ~ N^3"
  extends TRANSFORM.Icons.Example;
  // Two Pump_Controlled with the default head curve (Flow.PerformanceCurve) and the power curve
  // Power.PerformanceCurve, each fed by a mass flow source and discharging at 8 bar. pumpN runs at nominal speed and carries 6 kg/s; pumpS
  // runs at r_N = 0.5 of nominal speed and carries r_N times that, the similar operating point.
  // By the affinity laws pumpS's head is then r_N^2 = 0.25 times pumpN's and its power r_N^3 =
  // 0.125 times.
  //   dH: (head_S/head_N)/r_N^2 - 1, 0 when right. On TRANSFORM 1.3.0 the curve divided by the
  //       relative speed twice (in the affinity factor and again inside Math.PerformanceCurve):
  //       dH = -0.500 (pumpS gave half the head it should).
  //   dW: (W_S/W_N)/r_N^3 - 1, 0 when right. On TRANSFORM 1.3.0 Power.PerformanceCurve did not
  //       translate (its call passed the speed where the spline tangents go) and divided by the
  //       speed twice as well.
  // pumpS takes pumpN's nominal density (d_nominal defaults to the density at p_a_start, which
  // differs), so the two are the same pump; the gaps that remain come from the slightly denser
  // water at pumpS's higher inlet pressure.
  replaceable package Medium = Modelica.Media.Water.StandardWater;
  parameter SI.Temperature T = 303.15 "Water temperature";
  parameter Real r_N = 0.5 "Speed of pumpS over nominal";
  parameter Modelica.Units.NonSI.AngularVelocity_rpm N_nominal = 1500 "Nominal speed";
  parameter SI.MassFlowRate m_flow_N = 6 "Flow of pumpN";
  parameter SI.Pressure p_out = 8e5 "Outlet pressure of both pumps";
  TRANSFORM.Fluid.Machines.Pump_Controlled pumpN(redeclare package Medium = Medium,
    use_powerCharacteristic=true,
    redeclare model PowerChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Power.PerformanceCurve,
    controlType="RPM", N_nominal=N_nominal, N_input=N_nominal, p_a_start=5e5, p_b_start=p_out,
    T_a_start=T, m_flow_nominal=10, dp_nominal=2e5, m_flow_start=m_flow_N) "Nominal speed";
  TRANSFORM.Fluid.Machines.Pump_Controlled pumpS(redeclare package Medium = Medium,
    use_powerCharacteristic=true,
    redeclare model PowerChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Power.PerformanceCurve,
    controlType="RPM", N_nominal=N_nominal, N_input=r_N*N_nominal, d_nominal=pumpN.d_nominal,
    p_a_start=7e5,
    p_b_start=p_out, T_a_start=T, m_flow_nominal=10, dp_nominal=2e5,
    m_flow_start=r_N*m_flow_N) "Half speed";
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceN(redeclare package Medium = Medium,
    m_flow=m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceS(redeclare package Medium = Medium,
    m_flow=r_N*m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT outlet(redeclare package Medium = Medium,
    p=p_out, T=T, nPorts=2);
  Real dH = (pumpS.head/pumpN.head)/r_N^2 - 1 "Head ratio against the affinity law";
  Real dW = (pumpS.W/pumpN.W)/r_N^3 - 1 "Power ratio against the affinity law";
  TRANSFORM.Utilities.ErrorAnalysis.UnitTests unitTests(n=2, x={dH, dW})
    annotation (Placement(transformation(extent={{80,80},{100,100}})));
equation
  connect(sourceN.ports[1], pumpN.port_a);
  connect(pumpN.port_b, outlet.ports[1]);
  connect(sourceS.ports[1], pumpS.port_a);
  connect(pumpS.port_b, outlet.ports[2]);
  annotation (experiment(StopTime=1, __Dymola_Algorithm="Dassl"));
end Pump_SpeedAffinity;
