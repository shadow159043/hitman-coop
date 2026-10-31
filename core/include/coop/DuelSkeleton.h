#pragma once
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace coop::duel_skeleton {
struct Offset { float x=0, y=0, z=0; };
struct Joints {
    int shoulderA=-1, shoulderB=-1, upperTorso=-1;
    int candidatePairs=0;
};

// Read-only hierarchy inference; never modifies game-owned skeleton buffers.
// Avoid assuming that left/right directions use x: different animation rigs
// place mirror offsets along x, y or z. An ambiguous pair stays disabled.
inline Joints Detect(const std::vector<int32_t>& parents,
                     const std::vector<Offset>& local) {
    Joints out;
    const int n=static_cast<int>(parents.size());
    if (n<20 || n>512 || static_cast<int>(local.size())!=n ||
        parents[0]!=-1) return out;
    std::vector<int> depth(n), longest(n,0), desc(n,1);
    for(int i=1;i<n;++i) {
        if(parents[i]<0 || parents[i]>=i) return out;
        depth[i]=std::min(63,depth[parents[i]]+1);
    }
    for(int i=n-1;i>0;--i) {
        const int p=parents[i];
        longest[p]=std::max(longest[p],longest[i]+1);
        desc[p]+=desc[i];
    }
    // Follow the biggest upper-body branch from the root. It tends to contain
    // the shoulders, head and arms; the leg branches are smaller. Only choose
    // an upper torso once the chain reaches depth 3+.
    int torso=0;
    for(int steps=0;steps<8;++steps) {
        int best=-1;
        for(int i=1;i<n;++i)
            if(parents[i]==torso && (best<0 || desc[i]>desc[best]))
                best=i;
        if(best<0 || desc[best]<12) break;
        torso=best;
        if(depth[torso]>=4) {
            out.upperTorso=torso;
            break;
        }
    }
    float bestScore=-1.f;
    for(int p=1;p<n;++p) {
        if(depth[p]<3 || depth[p]>15 || desc[p]<9) continue;
        for(int a=p+1;a<n;++a) {
            if(parents[a]!=p || longest[a]<3 || desc[a]<4) continue;
            for(int b=a+1;b<n;++b) {
                if(parents[b]!=p || longest[b]<3 || desc[b]<4) continue;
                ++out.candidatePairs;
                const Offset u=local[a],v=local[b];
                const float us[3]={u.x,u.y,u.z},vs[3]={v.x,v.y,v.z};
                for(int axis=0;axis<3;++axis) {
                    const float x=us[axis],y=vs[axis];
                    if(!std::isfinite(x) || !std::isfinite(y) || x*y>=0.f ||
                       std::min(std::abs(x),std::abs(y))<.025f ||
                       std::max(std::abs(x),std::abs(y))>.95f) continue;
                    const float symmetry=std::abs(x+y)/
                        std::max(.01f,std::abs(x)+std::abs(y));
                    if(symmetry>.55f) continue;
                    float mismatch=0;
                    for(int k=0;k<3;++k) if(k!=axis) {
                        if(!std::isfinite(us[k]) || !std::isfinite(vs[k])) {
                            mismatch=100.f;break;
                        }
                        mismatch+=std::abs(us[k]-vs[k]);
                    }
                    if(mismatch>.5f) continue;
                    // Prefer near-identical mirror offsets, substantial arm
                    // chains and upper body over a pair of fingers.
                    const float chain=static_cast<float>(std::min(longest[a],longest[b]));
                    const float score=(1.f-symmetry)*4.f + std::min(chain,12.f)*.1f -
                        mismatch*1.5f + std::min(depth[p],9)*.025f;
                    if(score>bestScore) {
                        bestScore=score;out.shoulderA=a;out.shoulderB=b;
                        out.upperTorso=p;
                    }
                }
            }
        }
    }
    return out;
}
} // namespace coop::duel_skeleton
