#include "HitmanCoop.h"
#include "CoopText.h"
#include <algorithm>
#include <cmath>
#include <string>

void HitmanCoop::DrawDuel() {
    DuelState state;
    {
        std::lock_guard lock(m_StatusMutex);
        state = m_DuelView;
    }
    using Phase = DuelState::Phase;
    if (state.phase == Phase::Idle || state.phase == Phase::SentChallenge ||
        state.phase == Phase::ReceivedChallenge || state.phase == Phase::WaitingStart)
        return;
    const double now = Now();
    if (state.phase == Phase::Result && now - state.resultAt > 5.8) return;
    if (m_HideOverlay) return;
    const ImGuiViewport* view = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(ImVec2(view->Pos.x + view->Size.x * 0.5f,
        view->Pos.y + view->Size.y * 0.23f), ImGuiCond_Always, ImVec2(0.5f, 0.f));
    ImGui::SetNextWindowBgAlpha(0.83f);
    if (ImGui::Begin("##HitmanCoopFistDuel", nullptr,
            ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_AlwaysAutoResize |
            ImGuiWindowFlags_NoInputs | ImGuiWindowFlags_NoSavedSettings |
            ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoNav)) {
        ImGui::PushFont(nullptr, ImGui::GetStyle().FontSizeBase * 1.65f);
        ImGui::TextColored(ImVec4(1.f, .75f, .25f, 1.f), "FISTFIGHT");
        ImGui::PopFont();
        const double until = state.start - now;
        if (state.phase == Phase::Countdown) {
            ImGui::Text("Get ready! %.1f", std::max(0.0, until));
            ImGui::TextDisabled("Close CO-OP (~), then hit matching arrow keys");
        } else if (state.phase == Phase::Fighting) {
            const int round = coop::duel::Round(now, state.start);
            static constexpr const char* names[] = { "UP", "RIGHT", "DOWN", "LEFT" };
            if (round >= 0 && round < coop::duel::kRounds) {
                const int need = coop::duel::Prompt(state.seed, round);
                const double left = (round + 1) * coop::duel::kSecondsPerRound - (now - state.start);
                ImGui::Text("Round %d / %d   Time %.1fs", round + 1, coop::duel::kRounds, std::max(0.0, left));
                ImGui::PushFont(nullptr, ImGui::GetStyle().FontSizeBase * 2.8f);
                ImGui::TextColored(ImVec4(.45f, 1.f, .65f, 1.f), "%s", names[need]);
                ImGui::PopFont();
                ImGui::TextDisabled("One correct key per round. Wrong keys get no points.");
            }
        } else if (state.phase == Phase::WaitingResult) {
            ImGui::Text("Finished! Waiting for the scores...");
        } else if (state.phase == Phase::Result) {
            if (state.verdict > 0)
                ImGui::TextColored(ImVec4(.45f, 1.f, .65f, 1.f), "YOU WIN - PARTNER KNOCKED DOWN!");
            else if (state.verdict < 0) {
                ImGui::TextColored(ImVec4(1.f, .4f, .3f, 1.f), "YOU LOSE - KNOCKED DOWN!");
                if (now - state.resultAt < 3.0)
                    ImGui::Text("Recovering in %.1fs...", 3.0 - (now - state.resultAt));
            } else
                ImGui::Text("DRAW - both fought evenly!");
        }
        ImGui::Text("Your score: %d / %d", state.rhythm.score, coop::duel::kRounds);
        if (state.remoteScore >= 0)
            ImGui::Text("Partner score: %d / %d", state.remoteScore, coop::duel::kRounds);
    }
    ImGui::End();
}
