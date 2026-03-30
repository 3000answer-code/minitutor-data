import { useState } from 'react'
import { mockPushHistory } from '../../utils/mockData'

const emptyForm = { title: '', target: '전체', url: '', content: '' }

export default function PushSend() {
  const [history, setHistory] = useState(mockPushHistory)
  const [form, setForm] = useState(emptyForm)
  const [confirmModal, setConfirmModal] = useState(false)
  const [sending, setSending] = useState(false)
  const [sent, setSent] = useState(false)

  const handleSend = () => {
    if (!form.title) return alert('제목을 입력하세요')
    if (!form.content) return alert('내용을 입력하세요')
    setConfirmModal(true)
  }

  const confirmSend = () => {
    setConfirmModal(false)
    setSending(true)
    setTimeout(() => {
      setHistory(prev => [{
        id: Date.now(),
        title: form.title,
        target: form.target,
        sentDate: new Date().toLocaleString('ko-KR'),
        url: form.url || '-',
        content: form.content,
      }, ...prev])
      setForm(emptyForm)
      setSending(false)
      setSent(true)
      setTimeout(() => setSent(false), 3000)
    }, 1500)
  }

  const targets = {
    '전체': { label: '전체 회원', count: 12847, color: '#4f46e5', bg: '#ede9fe' },
    '유료회원': { label: '유료 회원', count: 3421, color: '#059669', bg: '#d1fae5' },
    '무료회원': { label: '무료 회원', count: 9426, color: '#d97706', bg: '#fef3c7' },
  }

  return (
    <div style={s.root}>
      <div style={s.cols}>
        {/* 발송 폼 */}
        <div style={s.sendBox}>
          <div style={s.boxTitle}>📱 푸시 알림 발송</div>

          {sent && (
            <div style={s.successAlert}>✅ 푸시 알림이 성공적으로 발송되었습니다!</div>
          )}

          {/* 대상 선택 */}
          <div style={s.targetSection}>
            <div style={s.sectionLabel}>발송 대상</div>
            <div style={s.targetCards}>
              {Object.entries(targets).map(([key, t]) => (
                <div
                  key={key}
                  style={{ ...s.targetCard, border: form.target === key ? `2px solid ${t.color}` : '2px solid #e5e7eb', background: form.target === key ? t.bg : '#fff' }}
                  onClick={() => setForm(p => ({ ...p, target: key }))}
                >
                  <div style={{ fontSize: 18 }}>{key === '전체' ? '🌐' : key === '유료회원' ? '💎' : '👤'}</div>
                  <div style={{ fontSize: 13, fontWeight: 700, color: form.target === key ? t.color : '#333' }}>{t.label}</div>
                  <div style={{ fontSize: 20, fontWeight: 800, color: form.target === key ? t.color : '#555' }}>{t.count.toLocaleString()}</div>
                  <div style={{ fontSize: 11, color: '#888' }}>명</div>
                </div>
              ))}
            </div>
          </div>

          <div style={s.mf}><label style={s.ml}>제목</label>
            <input style={s.mi} value={form.title} onChange={e => setForm(p => ({ ...p, title: e.target.value }))} placeholder="푸시 알림 제목" maxLength={50} />
            <span style={{ fontSize: 11, color: '#bbb', textAlign: 'right' }}>{form.title.length}/50</span>
          </div>
          <div style={s.mf}><label style={s.ml}>내용</label>
            <textarea style={{ ...s.mi, height: 100, resize: 'none' }} value={form.content} onChange={e => setForm(p => ({ ...p, content: e.target.value }))} placeholder="푸시 알림 내용" maxLength={200} />
            <span style={{ fontSize: 11, color: '#bbb', textAlign: 'right' }}>{form.content.length}/200</span>
          </div>
          <div style={s.mf}><label style={s.ml}>이동 URL (선택)</label>
            <input style={s.mi} value={form.url} onChange={e => setForm(p => ({ ...p, url: e.target.value }))} placeholder="/lecture/123 또는 https://..." />
          </div>

          {/* 미리보기 */}
          <div style={s.preview}>
            <div style={s.previewTitle}>📱 미리보기</div>
            <div style={s.previewBox}>
              <div style={s.previewNotif}>
                <div style={s.previewIcon}>🎓</div>
                <div style={s.previewText}>
                  <div style={s.previewNotifTitle}>{form.title || '제목 없음'}</div>
                  <div style={s.previewNotifContent}>{form.content || '내용이 여기에 표시됩니다.'}</div>
                </div>
              </div>
            </div>
          </div>

          <button style={s.sendBtn} onClick={handleSend} disabled={sending}>
            {sending ? '⏳ 발송 중...' : `📨 ${targets[form.target]?.count?.toLocaleString()}명에게 발송`}
          </button>
        </div>

        {/* 발송 내역 */}
        <div style={s.historyBox}>
          <div style={s.boxTitle}>📋 발송 내역</div>
          <div style={s.historyList}>
            {history.map(h => (
              <div key={h.id} style={s.historyItem}>
                <div style={s.historyHeader}>
                  <span style={s.historyTitle}>{h.title}</span>
                  <span style={{ ...s.targetTag, background: h.target === '전체' ? '#ede9fe' : h.target === '유료회원' ? '#d1fae5' : '#fef3c7', color: h.target === '전체' ? '#7c3aed' : h.target === '유료회원' ? '#059669' : '#d97706' }}>
                    {h.target}
                  </span>
                </div>
                <div style={s.historyContent}>{h.content}</div>
                <div style={s.historyMeta}>
                  <span>🔗 {h.url}</span>
                  <span style={{ marginLeft: 'auto' }}>📅 {h.sentDate}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 확인 모달 */}
      {confirmModal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>푸시 발송 확인</div>
            <div style={s.confirmContent}>
              <div style={s.confirmRow}><span>발송 대상</span><b>{targets[form.target]?.label} ({targets[form.target]?.count?.toLocaleString()}명)</b></div>
              <div style={s.confirmRow}><span>제목</span><b>{form.title}</b></div>
              <div style={s.confirmRow}><span>내용</span><span style={{ fontSize: 13, color: '#333' }}>{form.content}</span></div>
            </div>
            <p style={{ fontSize: 13, color: '#e53e3e', marginTop: 12 }}>⚠️ 발송 후 취소가 불가능합니다. 계속하시겠습니까?</p>
            <div style={s.mbtn}>
              <button style={s.btnPrimary} onClick={confirmSend}>발송 확인</button>
              <button style={s.btnOutline} onClick={() => setConfirmModal(false)}>취소</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const s = {
  root: {},
  cols: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 },
  sendBox: { background: '#fff', borderRadius: 14, padding: 24, boxShadow: '0 1px 4px rgba(0,0,0,0.06)', display: 'flex', flexDirection: 'column', gap: 16 },
  historyBox: { background: '#fff', borderRadius: 14, padding: 24, boxShadow: '0 1px 4px rgba(0,0,0,0.06)' },
  boxTitle: { fontSize: 16, fontWeight: 700, color: '#1a1a2e' },
  successAlert: { background: '#d1fae5', color: '#065f46', padding: '12px 16px', borderRadius: 10, fontSize: 14, fontWeight: 600 },
  targetSection: { display: 'flex', flexDirection: 'column', gap: 8 },
  sectionLabel: { fontSize: 12, fontWeight: 600, color: '#666' },
  targetCards: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 },
  targetCard: { borderRadius: 10, padding: '12px 10px', cursor: 'pointer', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2, transition: 'all 0.15s' },
  mf: { display: 'flex', flexDirection: 'column', gap: 4 }, ml: { fontSize: 12, color: '#666', fontWeight: 600 },
  mi: { padding: '10px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  preview: { background: '#f8f9fa', borderRadius: 10, padding: 16 },
  previewTitle: { fontSize: 12, fontWeight: 600, color: '#888', marginBottom: 12 },
  previewBox: { background: '#fff', borderRadius: 8, padding: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.08)' },
  previewNotif: { display: 'flex', gap: 12, alignItems: 'flex-start' },
  previewIcon: { width: 36, height: 36, background: '#ede9fe', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18, flexShrink: 0 },
  previewText: { flex: 1 },
  previewNotifTitle: { fontSize: 14, fontWeight: 700, color: '#1a1a2e', marginBottom: 4 },
  previewNotifContent: { fontSize: 12, color: '#555', lineHeight: 1.5 },
  sendBtn: { padding: '14px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 10, fontSize: 15, fontWeight: 700, cursor: 'pointer', letterSpacing: 0.5 },
  historyList: { display: 'flex', flexDirection: 'column', gap: 12, marginTop: 16, maxHeight: 600, overflowY: 'auto' },
  historyItem: { border: '1px solid #f0f0f0', borderRadius: 10, padding: 14 },
  historyHeader: { display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 },
  historyTitle: { fontSize: 14, fontWeight: 700, color: '#1a1a2e', flex: 1 },
  targetTag: { padding: '2px 8px', borderRadius: 6, fontSize: 11, fontWeight: 600 },
  historyContent: { fontSize: 13, color: '#555', lineHeight: 1.6, marginBottom: 8 },
  historyMeta: { display: 'flex', fontSize: 11, color: '#bbb' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 460, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 20, color: '#1a1a2e' },
  confirmContent: { display: 'flex', flexDirection: 'column', gap: 12, background: '#f8f9fa', borderRadius: 10, padding: 16 },
  confirmRow: { display: 'flex', gap: 12, fontSize: 13, alignItems: 'flex-start' },
  mbtn: { display: 'flex', gap: 10, marginTop: 24, justifyContent: 'flex-end' },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
}
