function [ cnumsol ] = compute_numerical(cinit, xx, yy, zz, u, v, w, t, dt, tn, INTERP_TYPE, NUM_SCHEME)
%COMPUTE_NUMERICAL
global DEBUG;

cnumsol = cinit;
fprintf('computing numerical solution:\n');
for tstep=1:tn
    fprintf('scheme: %s interp.: %s timestep: %d time:%f\n', NUM_SCHEME, INTERP_TYPE, tstep,tstep*dt);
    switch NUM_SCHEME
        case 'rk2'
            cnumsol(:,:,:,tstep+1) = semilag_rk2(xx,yy,zz,@conc,@vel_prec,t);
            % clear the persistent precomputed velociy values for the previous time step
            interp_vel_precomputed(0,0,0,0,0,0,0,0,0,0,0,0,0,true);
        case '2tl'
            cnumsol(:,:,:,tstep+1) = semilag_2tl(xx,yy,zz,@conc,u,v,w,tstep,dt,INTERP_TYPE);
        otherwise
            error('Numerical scheme is unknown.');
    end
    assert(sum(sum(sum(isnan(cnumsol(:,:,:,tstep+1))))) == 0,'NaN found in solution data.');

    % get the velocity values for the next time step
    t = t + dt;
    for tcnt=1:length(t)
        [u(:,:,:,tcnt), v(:,:,:,tcnt), w(:,:,:,tcnt)] = vel_rot(t(tcnt),xx,yy,zz,0.5,0.5,0.5);
    end
end

    %/* ************************************************** */
    function ci = conc(t,xt,yt,zt)
        ci = interp_conc_spatial(cnumsol(:,:,:,tstep),xx,yy,zz,xt,yt,zt,INTERP_TYPE,@conc_out);

        function cq = conc_out(cq,xq,yq,zq)
            out = xq<0 | xq>1  | yq<0 | yq>1 | zq<0 | zq>1;
            cq(out) = 0;
        end
    end

    %/* ************************************************** */
    function [uq,vq,wq] = vel_prec(tq,xq,yq,zq)
        [uq,vq,wq] = interp_vel_precomputed(xx,yy,zz,u,v,w,t,tq,xq,yq,zq,INTERP_TYPE,@vel_out);

        function [uq,vq,wq] = vel_out(uq,vq,wq,xq,yq,zq)
            out = xq<0 | xq>1  | yq<0 | yq>1 | zq<0 | zq>1;
            [ue, ve, we] = vel_rot(tq,xq,yq,zq,0.5,0.5,0.5);
            uq(out) = ue(out);
            vq(out) = ve(out);
            wq(out) = we(out);
        end
    end

    %/* ************************************************** */
    function [uq,vq,wq] = vel(tq,xq,yq,zq)
        [ut, vt, wt] = interp_vel_temporal(u,v,w,t,tq,INTERP_TYPE);
        [uq, vq, wq] = interp_vel_spatial(xx,yy,zz,ut,vt,wt,xq,yq,zq,INTERP_TYPE,@vel_out);

        function [uq,vq,wq] = vel_out(uq,vq,wq,xq,yq,zq)
            out = xq<0 | xq>1  | yq<0 | yq>1 | zq<0 | zq>1;
            [ue, ve, we] = vel_rot(tq,xq,yq,zq,0.5,0.5,0.5);
            uq(out) = ue(out);
            vq(out) = ve(out);
            wq(out) = we(out);
        end
    end
end
