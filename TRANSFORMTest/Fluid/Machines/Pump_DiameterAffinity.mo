within TRANSFORMTest.Fluid.Machines;
model Pump_DiameterAffinity
  "A pump with a larger impeller must follow the affinity laws: flow ~ D^3, head ~ D^2, power ~ D^5"
  extends TRANSFORM.Icons.Example;
  // Two Pumps at nominal speed with the default head curve (Head.PerformanceCurve) and the power
  // curve Power.PerformanceCurve, each fed by a mass flow source and discharging at 8 bar. pumpN has
  // the nominal impeller and carries 6 kg/s; pumpD has an impeller r_D = 1.2 times larger and
  // carries r_D^3 = 1.728 times that, the similar operating point. By the affinity laws pumpD's head
  // is then r_D^2 = 1.44 times pumpN's and its power r_D^5 = 2.48832 times.
  //   dH: (head_D/head_N)/r_D^2 - 1, 0 when right. On TRANSFORM 1.3.0 the head curve did not scale
  //       the flow by r_D^3, so pumpD was read at 1.728 times pumpN's flow on the nominal curve:
  //       dH = -0.360 (Dymola and OpenModelica).
  //   dW: (W_D/W_N)/r_D^5 - 1, 0 when right. On TRANSFORM 1.3.0 the power curve scaled by r_D^3
  //       and did not scale the flow either: dW = +0.391.
  // Both are 0 only to within the small difference between the two pumps' densities.
  replaceable package Medium = Modelica.Media.Water.StandardWater;
  parameter SI.Temperature T = 303.15 "Water temperature";
  parameter Real r_D = 1.2 "Impeller diameter of pumpD over nominal";
  parameter SI.MassFlowRate m_flow_N = 6 "Flow of pumpN (both pumps stay on their curves on 1.3.0 too)";
  parameter SI.Pressure p_out = 8e5 "Outlet pressure of both pumps (inlets stay well above saturation)";
  TRANSFORM.Fluid.Machines.Pump pumpN(redeclare package Medium = Medium,
    use_powerCharacteristic=true,
    redeclare model PowerChar =
      TRANSFORM.Fluid.ClosureRelations.PumpCharacteristics.Models.Power.PerformanceCurve,
    p_a_start=5e5, p_b_start=p_out, T_start=T, m_flow_nominal=10, dp_nominal=2e5,
    m_flow_start=m_flow_N) "Nominal impeller";
  TRANSFORM.Fluid.Machines.Pump pumpD(redeclare package Medium = Medium,
    use_powerCharacteristic=true,
    redeclare model PowerChar =
      TRANSFORM.Fluid.ClosureRelations.PumpCharacteristics.Models.Power.PerformanceCurve,
    diameter=r_D*pumpD.diameter_nominal, p_a_start=5e5, p_b_start=p_out, T_start=T,
    m_flow_nominal=10, dp_nominal=2e5, m_flow_start=r_D^3*m_flow_N)
    "Impeller r_D times larger";
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceN(redeclare package Medium = Medium,
    m_flow=m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceD(redeclare package Medium = Medium,
    m_flow=r_D^3*m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT outlet(redeclare package Medium = Medium,
    p=p_out, T=T, nPorts=2);
  Real dH = (pumpD.head/pumpN.head)/r_D^2 - 1 "Head ratio against the affinity law";
  Real dW = (pumpD.W/pumpN.W)/r_D^5 - 1 "Power ratio against the affinity law";
  TRANSFORM.Utilities.ErrorAnalysis.UnitTests unitTests(n=2, x={dH, dW})
    annotation (Placement(transformation(extent={{80,80},{100,100}})));
equation
  connect(sourceN.ports[1], pumpN.port_a);
  connect(pumpN.port_b, outlet.ports[1]);
  connect(sourceD.ports[1], pumpD.port_a);
  connect(pumpD.port_b, outlet.ports[2]);
  annotation (experiment(StopTime=1, __Dymola_Algorithm="Dassl"));
end Pump_DiameterAffinity;
