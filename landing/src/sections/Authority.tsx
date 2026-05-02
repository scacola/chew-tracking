import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { StatusChip } from '../components/StatusChip'

export function Authority() {
  return (
    <Section tone="mist" paddingY="xl" id="authority">
      <Container size="narrow">
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          꾸며진 후기 대신,
          <br className="md:hidden" /> 지금 우리가 진짜 하고 있는 일을 보여드려요.
        </h2>

        <div data-reveal-stagger className="mt-12 space-y-5 lg:mt-16">
          {/* 카드 1 — 임상 RCT */}
          <div
            data-reveal
            className="rounded-2xl border border-line bg-bg-cool p-7 transition-shadow hover:shadow-md md:p-8"
          >
            <div className="mb-4 flex items-center gap-3">
              <StatusChip status="inProgress" label="진행 중" />
              <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
                임상 RCT 진행 중
              </h3>
            </div>
            <p className="text-body leading-relaxed text-text-secondary">
              식사 속도 개선과 위 건강 점수의 상관관계를 검증하는 RCT 8주차 진행 중.
              학술 발표 가능 형식으로 익명화 누적 중.
              <br />
              <em className="not-italic text-text-muted">완료 시점: 2026년 4분기 예정.</em>
            </p>
            {/* 작은 진행 막대 */}
            <div className="mt-5 flex items-center gap-3">
              <span className="text-caption text-text-muted">8주차 / 12주</span>
              <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-line">
                <div
                  className="h-full rounded-full bg-clinical transition-[width] duration-1000 ease-reveal"
                  style={{ width: '67%' }}
                />
              </div>
              <span className="text-caption font-mono text-clinical-deep">67%</span>
            </div>
          </div>

          {/* 카드 2 — 임상 메타분석 근거 */}
          <div
            data-reveal
            className="rounded-2xl border border-line bg-bg-cool p-7 transition-shadow hover:shadow-md md:p-8"
          >
            <div className="mb-4 flex items-center gap-3">
              <StatusChip status="live" label="공개 근거" />
              <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
                임상 메타분석 근거
              </h3>
            </div>
            <p className="mb-5 text-body leading-relaxed text-text-secondary">
              우리가 약속하는 <span className="font-medium text-text-primary">위 건강 회복</span>의
              근거는 우리 자체 데이터가 아니라,{' '}
              이미 발표된 메타분석에 있어요. 누구든 출처를 직접 확인할 수 있어요.
            </p>
            <ul className="space-y-3 text-body-sm text-text-secondary">
              <li className="flex items-start gap-3">
                <span className="mt-1 inline-block h-1.5 w-1.5 shrink-0 rounded-full bg-clinical" />
                <span>
                  빠른 식사군 미란성 위염 위험 <span className="font-mono text-clinical-deep">+71%</span> —{' '}
                  Hurst & Fukuda, 위장관 메타분석 (2018)
                </span>
              </li>
              <li className="flex items-start gap-3">
                <span className="mt-1 inline-block h-1.5 w-1.5 shrink-0 rounded-full bg-clinical" />
                <span>
                  빠른 식사 → 비만 위험 <span className="font-mono text-clinical-deep">2.15배</span> —{' '}
                  Ohkuma et al., 식이 속도 코호트 연구 (2015)
                </span>
              </li>
            </ul>
          </div>

          {/* 카드 3 — 베타 모집 */}
          <div
            data-reveal
            className="rounded-2xl border border-line bg-bg-cool p-7 transition-shadow hover:shadow-md md:p-8"
          >
            <div className="mb-4 flex items-center gap-3">
              <StatusChip status="beta" label="베타 모집 중" />
              <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
                베타 모집 중
              </h3>
            </div>
            <p className="text-body leading-relaxed text-text-secondary">
              현재 시점, 베타 사용자 모집 중.
              <br />
              <span className="font-medium text-text-primary">
                1만 명이 사용 중이라고 거짓말하지 않아요.
              </span>
              <br />
              <em className="not-italic text-text-muted">
                베타 합류 시: 8주 코스 무료 + 정식 출시 시 50% 평생 할인.
              </em>
            </p>
          </div>
        </div>

        {/* 닫는 메시지 */}
        <p
          data-reveal
          className="mx-auto mt-16 max-w-prose-narrow text-center text-body-lg leading-relaxed text-text-secondary"
        >
          우리는 <span className="font-medium text-text-primary">화려한 권위</span> 대신,
          <br />
          <span className="font-medium text-text-primary">투명한 진행 상태</span>로 신뢰를 쌓고 있어요.
        </p>
      </Container>
    </Section>
  )
}
