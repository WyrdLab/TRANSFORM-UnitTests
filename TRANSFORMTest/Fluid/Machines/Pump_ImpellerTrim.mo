within TRANSFORMTest.Fluid.Machines;
model Pump_ImpellerTrim
  "With impellerScaling = Trimmed a pump with a cut-down impeller follows the trimming laws: flow ~ D, head ~ D^2, power ~ D^3"
  extends TRANSFORM.Icons.Example;
  // Four pairs of pumps at nominal speed, each fed by a mass flow source and discharging at 8 bar.
  // In each pair the first pump has the nominal impeller and carries 6 kg/s; the second has its
  // impeller trimmed to r_D = 0.9 (impellerScaling = Trimmed) and carries r_D times that, the
  // similar operating point. By the trimming laws its head is then r_D^2 = 0.81 times the first
  // one's, its power r_D^3 = 0.729 times and its efficiency the same. The trimmed pump takes the
  // nominal pump's nominal density, so the two are the same pump.
  //   dH_P, dW_P:   Pump with Head.PerformanceCurve and Power.PerformanceCurve (ClosureRelations).
  //   dH_PC, dW_PC: Pump_Controlled with Flow.PerformanceCurve and Power.PerformanceCurve (Machines).
  //   dH_Q:         Pump_Controlled with Flow.Quadratic.
  //   deta_P:       Pump with Efficiency.QuadraticCurve: efficiency ratio - 1.
  // Each is (ratio)/(trimming law) - 1, 0 when right, to within the slightly denser water at the
  // trimmed pumps' higher inlet pressure. The parameter does not exist before TRANSFORM 1.4.0.
  replaceable package Medium = Modelica.Media.Water.StandardWater;
  parameter SI.Temperature T = 303.15 "Water temperature";
  parameter Real r_D = 0.9 "Trimmed impeller diameter over nominal";
  parameter SI.MassFlowRate m_flow_N = 6 "Flow of the nominal pumps";
  parameter SI.Pressure p_out = 8e5 "Outlet pressure of all pumps";

  TRANSFORM.Fluid.Machines.Pump pN(redeclare package Medium = Medium,
    use_powerCharacteristic=true, redeclare model PowerChar =
      TRANSFORM.Fluid.ClosureRelations.PumpCharacteristics.Models.Power.PerformanceCurve,
    p_a_start=5e5, p_b_start=p_out, T_start=T, m_flow_nominal=10, dp_nominal=2e5,
    m_flow_start=m_flow_N) "Pump, nominal impeller";
  TRANSFORM.Fluid.Machines.Pump pT(redeclare package Medium = Medium,
    use_powerCharacteristic=true, redeclare model PowerChar =
      TRANSFORM.Fluid.ClosureRelations.PumpCharacteristics.Models.Power.PerformanceCurve,
    impellerScaling=TRANSFORM.Fluid.Types.ImpellerScaling.Trimmed,
    diameter=r_D*pT.diameter_nominal, d_nominal=pN.d_nominal,
    p_a_start=5.5e5, p_b_start=p_out, T_start=T, m_flow_nominal=10, dp_nominal=2e5,
    m_flow_start=r_D*m_flow_N) "Pump, trimmed impeller";

  TRANSFORM.Fluid.Machines.Pump_Controlled pcN(redeclare package Medium = Medium,
    use_powerCharacteristic=true, redeclare model PowerChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Power.PerformanceCurve,
    controlType="RPM", p_a_start=5e5, p_b_start=p_out, T_a_start=T, m_flow_nominal=10,
    dp_nominal=2e5, m_flow_start=m_flow_N) "Pump_Controlled, nominal impeller";
  TRANSFORM.Fluid.Machines.Pump_Controlled pcT(redeclare package Medium = Medium,
    use_powerCharacteristic=true, redeclare model PowerChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Power.PerformanceCurve,
    impellerScaling=TRANSFORM.Fluid.Types.ImpellerScaling.Trimmed,
    diameter=r_D*pcT.diameter_nominal, d_nominal=pcN.d_nominal,
    controlType="RPM", p_a_start=5.5e5, p_b_start=p_out, T_a_start=T, m_flow_nominal=10,
    dp_nominal=2e5, m_flow_start=r_D*m_flow_N) "Pump_Controlled, trimmed impeller";

  TRANSFORM.Fluid.Machines.Pump_Controlled qN(redeclare package Medium = Medium,
    redeclare model FlowChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Flow.Quadratic,
    controlType="RPM", p_a_start=5e5, p_b_start=p_out, T_a_start=T, m_flow_nominal=10,
    dp_nominal=2e5, m_flow_start=m_flow_N) "Quadratic curve, nominal impeller";
  TRANSFORM.Fluid.Machines.Pump_Controlled qT(redeclare package Medium = Medium,
    redeclare model FlowChar =
      TRANSFORM.Fluid.Machines.BaseClasses.PumpCharacteristics.Flow.Quadratic,
    impellerScaling=TRANSFORM.Fluid.Types.ImpellerScaling.Trimmed,
    diameter=r_D*qT.diameter_nominal, d_nominal=qN.d_nominal,
    controlType="RPM", p_a_start=5.5e5, p_b_start=p_out, T_a_start=T, m_flow_nominal=10,
    dp_nominal=2e5, m_flow_start=r_D*m_flow_N) "Quadratic curve, trimmed impeller";

  TRANSFORM.Fluid.Machines.Pump eN(redeclare package Medium = Medium,
    redeclare model EfficiencyChar =
      TRANSFORM.Fluid.ClosureRelations.PumpCharacteristics.Models.Efficiency.QuadraticCurve,
    p_a_start=5e5, p_b_start=p_out, T_start=T, m_flow_nominal=10, dp_nominal=2e5,
    m_flow_start=m_flow_N) "Efficiency curve, nominal impeller";
  TRANSFORM.Fluid.Machines.Pump eT(redeclare package Medium = Medium,
    redeclare model EfficiencyChar =
      TRANSFORM.Fluid.ClosureRelations.PumpCharacteristics.Models.Efficiency.QuadraticCurve,
    impellerScaling=TRANSFORM.Fluid.Types.ImpellerScaling.Trimmed,
    diameter=r_D*eT.diameter_nominal, d_nominal=eN.d_nominal,
    p_a_start=5.5e5, p_b_start=p_out, T_start=T, m_flow_nominal=10, dp_nominal=2e5,
    m_flow_start=r_D*m_flow_N) "Efficiency curve, trimmed impeller";

  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceN1(redeclare package Medium = Medium,
    m_flow=m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceN2(redeclare package Medium = Medium,
    m_flow=m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceN3(redeclare package Medium = Medium,
    m_flow=m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceN4(redeclare package Medium = Medium,
    m_flow=m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceT1(redeclare package Medium = Medium,
    m_flow=r_D*m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceT2(redeclare package Medium = Medium,
    m_flow=r_D*m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceT3(redeclare package Medium = Medium,
    m_flow=r_D*m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T sourceT4(redeclare package Medium = Medium,
    m_flow=r_D*m_flow_N, T=T, nPorts=1);
  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT outlet(redeclare package Medium = Medium,
    p=p_out, T=T, nPorts=8);

  Real dH_P = (pT.head/pN.head)/r_D^2 - 1 "Pump: head ratio against the trimming law";
  Real dW_P = (pT.W/pN.W)/r_D^3 - 1 "Pump: power ratio against the trimming law";
  Real dH_PC = (pcT.head/pcN.head)/r_D^2 - 1 "Pump_Controlled: head ratio against the trimming law";
  Real dW_PC = (pcT.W/pcN.W)/r_D^3 - 1 "Pump_Controlled: power ratio against the trimming law";
  Real dH_Q = (qT.head/qN.head)/r_D^2 - 1 "Quadratic: head ratio against the trimming law";
  Real deta_P = eT.eta/eN.eta - 1 "Pump: efficiency ratio, 1 when right";
  TRANSFORM.Utilities.ErrorAnalysis.UnitTests unitTests(n=6, x={dH_P, dW_P, dH_PC, dW_PC, dH_Q,
    deta_P})
    annotation (Placement(transformation(extent={{80,80},{100,100}})));
equation
  connect(sourceN1.ports[1], pN.port_a);
  connect(sourceN2.ports[1], pcN.port_a);
  connect(sourceN3.ports[1], qN.port_a);
  connect(sourceN4.ports[1], eN.port_a);
  connect(sourceT1.ports[1], pT.port_a);
  connect(sourceT2.ports[1], pcT.port_a);
  connect(sourceT3.ports[1], qT.port_a);
  connect(sourceT4.ports[1], eT.port_a);
  connect(pN.port_b, outlet.ports[1]);
  connect(pT.port_b, outlet.ports[2]);
  connect(pcN.port_b, outlet.ports[3]);
  connect(pcT.port_b, outlet.ports[4]);
  connect(qN.port_b, outlet.ports[5]);
  connect(qT.port_b, outlet.ports[6]);
  connect(eN.port_b, outlet.ports[7]);
  connect(eT.port_b, outlet.ports[8]);
  annotation (experiment(StopTime=1, __Dymola_Algorithm="Dassl"));
end Pump_ImpellerTrim;
