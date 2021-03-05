clear all
syms x y z dx dy dz phi theta psi p q r alpha beta m Ixx Iyy Izz g J_prop k lambda l_l l_s O1 O2 O3 O4 Lf Lr Df Dr real

s = [x y z phi theta psi]';
s_dot = [dx dy dz p q r]';
Omega = [O1 O2 O3 O4]';
w_b = s_dot(4:6);
gamma = [alpha;alpha;beta;beta];
n = [1,-1,1,-1];

% Inertia and coriolis matricies

mass = m*eye(3);
inertia = [Ixx, 0, 0;
            0, Iyy, 0;
            0, 0, Izz];

M = mass * eye(3);
M = [M, zeros(3,3);
    zeros(3,3), inertia];
        
skew = inertia*s_dot(4:6);
C = [zeros(3,3), zeros(3,3);
     zeros(1,3), 0, skew(3), -skew(2);
     zeros(1,3), -skew(3), 0, skew(1);
     zeros(1,3), skew(2), -skew(1), 0];
        
% Transformation matrix from the body frame to the world frame
R = [cos(psi)*cos(theta), -sin(psi)*cos(phi) + cos(psi)*sin(theta)*sin(phi), sin(psi)*sin(phi) + cos(psi)*sin(theta)*cos(phi);
     sin(psi)*cos(theta), cos(psi)*cos(phi) + sin(psi)*sin(theta)*sin(phi), -cos(psi)*sin(phi) + sin(psi)*sin(theta)*cos(phi);
     -sin(theta), cos(theta)*sin(phi), cos(theta)*cos(phi)];

% Thrust generated by the spinning motor
Thrust = [k*Omega(1)^2; k*Omega(2)^2; k*Omega(3)^2; k*Omega(4)^2];
 
% Calculate the forces from the thrust in the body frame
F_angles = [cos(gamma(1)), cos(gamma(2)), cos(gamma(3)), cos(gamma(4));
                  0,             0,             0,             0;
            -sin(gamma(1)), -sin(gamma(2)), -sin(gamma(3)), -sin(gamma(4))];
       
F_thrust = F_angles * Thrust;

% Calculate the moments from the thrust in the body frame
M_arms = [l_s*sin(gamma(1)) - lambda*n(1)*cos(gamma(1)), -l_s*sin(gamma(2)) - lambda*n(2)*cos(gamma(2)), -l_s*sin(gamma(3)) - lambda*n(3)*cos(gamma(3)), l_s*sin(gamma(4)) - lambda*n(4)*cos(gamma(4));
          l_l * sin(gamma(1)), l_l * sin(gamma(2)), -l_l * sin(gamma(3)), -l_l * sin(gamma(4));
          l_s*cos(gamma(1)) + lambda*n(1)*sin(gamma(1)), -l_s*cos(gamma(2)) + lambda*n(2)*sin(gamma(2)), -l_s*cos(gamma(3)) + lambda*n(3)*sin(gamma(3)), l_s*cos(gamma(4)) + lambda*n(4)*sin(gamma(4))];

M_thrust = M_arms * Thrust;
      
% Convert the forces and moments to the hybrid frame 
E = [R*F_thrust;
     M_thrust];
 
% Gravity
G = m*[0;0;9.8;0;0;0];
 
% Gyroscopic force matrix in the body frame
gyro = [0;0;0];
for i = 1:4
    gamma_vector = [cos(gamma(i)); 0; -sin(gamma(i))];
    new_vector  = cross(n(i)*w_b, gamma_vector*Omega(i));
    gyro = gyro + new_vector;
end

O = J_prop * [zeros(3,1); gyro];

Fw = [2*(Df + Dr); 0; 2*(Lf + Lr)];
Tw = [0; 2*l_l*(Lf - Lr);0];

W = [R*Fw; Tw];

acc = M\(-C*s_dot + G + O + E + W);
% acc = M\(-C*s_dot + W);
acc = simplify(acc);
 