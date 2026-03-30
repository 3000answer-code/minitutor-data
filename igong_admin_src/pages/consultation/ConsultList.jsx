import { useState } from 'react'
import { mockConsultations } from '../../utils/mockData'

export default function ConsultList() {
  const [list, setList] = useState(mockConsultations)
  const [search, setSearch] = useState({ userId: '', answered: '' })
  const [page, setPage] = useState(1)
  const [pageSize] = useState(10)
  const [replyModal, setReplyModal] = useState(false)
  const [selected, setSelected] = useState(null)
  const [replyText, setReplyText] = useState('')

  const filtered = list.filter(q =>
    (!search.userId || q.userId.includes(search.userId)) &&
    (!search.answered || (search.answered === 'Y' ? q.answered : !q.answered))
  )
  const total = filtered.length
  const paged = filtered.slice((page - 1) * pageSize, page * pageSize)
  const totalPages = Math.ceil(total / pageSize)

  const openReply = (item) => { setSelected(item); setReplyText(item.reply || ''); setReplyModal(true) }
  const saveReply = () => {
    setList(prev => prev.map(q => q.id === selected.id ? { ...q, answered: true, reply: replyText, replyDate: new Date().toISOString().slice(0, 10) } : q))
    setReplyModal(false)
  }
  const del = (id) => { if (confirm('삭제하시겠습니까?')) setList(prev => prev.filter(q => q.id !== id)) }

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        <div style={s.sf}><span style={s.sl}>아이디</span>
          <input style={s.si} value={search.userId} onChange={e => setSearch(p => ({ ...p, userId: e.target.value }))} placeholder="회원 아이디" />
        </div>
        <div style={s.sf}><span style={s.sl}>답변상태</span>
          <select style={{ ...s.si, width: 120 }} value={search.answered} onChange={e => setSearch(p => ({ ...p, answered: e.target.value }))}>
            <option value="">전체</option><option value="Y">답변완료</option><option value="N">답변대기</option>
          </select>
        </div>
        <button style={s.btnOutline} onClick={() => setSearch({ userId: '', answered: '' })}>초기화</button>
      </div>

      <div style={s.tableHeader}><span style={s.total}>총 <b>{total}</b>건</span></div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>{['번호', '이름', '아이디', '닉네임', '내용', '등록일', '답변상태', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {paged.map(q => (
              <tr key={q.id} style={styles.tr}>
                <td style={styles.td}>{q.id}</td>
                <td style={styles.td}>{q.name}</td>
                <td style={styles.td}>{q.userId}</td>
                <td style={styles.td}>{q.nickname}</td>
                <td style={{ ...styles.td, maxWidth: 240 }}><div style={styles.truncate}>{q.content}</div></td>
                <td style={styles.td}>{q.regDate}</td>
                <td style={styles.td}>
                  <span style={{ ...styles.badge, background: q.answered ? '#d1fae5' : '#fff7ed', color: q.answered ? '#059669' : '#d97706' }}>
                    {q.answered ? '답변완료' : '답변대기'}
                  </span>
                </td>
                <td style={styles.td}>
                  <button style={styles.btnSm} onClick={() => openReply(q)}>{q.answered ? '수정' : '답변'}</button>
                  <button style={{ ...styles.btnSm, ...styles.btnDanger }} onClick={() => del(q.id)}>삭제</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={s.pagination}>
        <button style={s.pageBtn} onClick={() => setPage(1)} disabled={page === 1}>{'<<'}</button>
        <button style={s.pageBtn} onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>{'<'}</button>
        {Array.from({ length: Math.min(5, totalPages) }, (_, i) => { const p = Math.max(1, page - 2) + i; return p <= totalPages ? <button key={p} style={{ ...s.pageBtn, ...(p === page ? s.pageBtnActive : {}) }} onClick={() => setPage(p)}>{p}</button> : null })}
        <button style={s.pageBtn} onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>{'>'}</button>
        <button style={s.pageBtn} onClick={() => setPage(totalPages)} disabled={page === totalPages}>{'>>'}</button>
      </div>

      {replyModal && selected && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>전문가 상담 답변</div>
            <div style={s.qBox}>
              <div style={s.qLabel}>질문</div>
              <div style={s.qContent}>{selected.content}</div>
              <div style={s.qMeta}>{selected.name} ({selected.userId}) · {selected.regDate}</div>
            </div>
            <div style={s.mf}><label style={s.ml}>답변 내용</label>
              <textarea style={s.textarea} rows={5} value={replyText} onChange={e => setReplyText(e.target.value)} placeholder="답변을 입력하세요..." />
            </div>
            <div style={s.mbtn}>
              <button style={s.btnPrimary} onClick={saveReply}>답변 저장 (푸시 발송)</button>
              <button style={s.btnOutline} onClick={() => setReplyModal(false)}>취소</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const s = {
  root: { display: 'flex', flexDirection: 'column', gap: 16 },
  searchBox: { background: '#fff', borderRadius: 12, padding: '16px 20px', display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  sf: { display: 'flex', alignItems: 'center', gap: 8 }, sl: { fontSize: 13, color: '#555', whiteSpace: 'nowrap', fontWeight: 600 },
  si: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, width: 140 },
  tableHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  total: { fontSize: 13, color: '#555' },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse', minWidth: 800 },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  pagination: { display: 'flex', gap: 6, alignItems: 'center', justifyContent: 'center' },
  pageBtn: { padding: '6px 12px', border: '1.5px solid #e5e7eb', borderRadius: 7, fontSize: 13, cursor: 'pointer', background: '#fff' },
  pageBtnActive: { background: '#4f46e5', color: '#fff', borderColor: '#4f46e5' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 520, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 20, color: '#1a1a2e' },
  qBox: { background: '#f8f9fa', borderRadius: 10, padding: 16, marginBottom: 16 },
  qLabel: { fontSize: 11, fontWeight: 700, color: '#7c3aed', marginBottom: 8 },
  qContent: { fontSize: 14, color: '#1a1a2e', lineHeight: 1.6 }, qMeta: { fontSize: 11, color: '#888', marginTop: 8 },
  mf: { display: 'flex', flexDirection: 'column', gap: 4 }, ml: { fontSize: 12, color: '#666', fontWeight: 600 },
  textarea: { padding: '12px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, resize: 'vertical', fontFamily: 'inherit' },
  mbtn: { display: 'flex', gap: 10, marginTop: 20, justifyContent: 'flex-end' },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
}
const styles = {
  tr: { borderBottom: '1px solid #fafafa' }, td: { padding: '10px 12px', fontSize: 13, color: '#333' },
  badge: { padding: '3px 10px', borderRadius: 20, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer', marginRight: 4 },
  btnDanger: { background: '#fff0f0', color: '#e53e3e' }, truncate: { maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' },
}
