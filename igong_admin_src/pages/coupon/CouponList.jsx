import { useState } from 'react'
import { mockCoupons } from '../../utils/mockData'

const COUPON_TYPES = ['할인율', '정액할인', '강의기간']
const emptyForm = { name: '', header: '', type: '할인율', discountValue: '', quantity: '', expiry: '', status: '사용중' }

const sampleCodes = (couponId) => Array.from({ length: 5 }, (_, i) => ({
  id: i + 1,
  code: `CPT-${couponId}-${String(Math.random()).slice(2, 8).toUpperCase()}`,
  regDate: '2025-03-01',
  userId: i % 2 === 0 ? `user00${i + 1}` : '-',
}))

export default function CouponList() {
  const [coupons, setCoupons] = useState(mockCoupons)
  const [modal, setModal] = useState(false)
  const [detailModal, setDetailModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [selectedCoupon, setSelectedCoupon] = useState(null)

  const openAdd = () => { setForm(emptyForm); setModal(true) }
  const save = () => {
    if (!form.name) return alert('쿠폰명을 입력하세요')
    if (!form.quantity) return alert('발행수량을 입력하세요')
    setCoupons(prev => [...prev, { ...form, id: Date.now(), issueDate: new Date().toISOString().slice(0, 10), used: 0 }])
    setModal(false)
  }
  const openDetail = (c) => { setSelectedCoupon(c); setDetailModal(true) }
  const toggleStatus = (id) => {
    setCoupons(prev => prev.map(c => c.id === id ? { ...c, status: c.status === '사용중' ? '중지' : '사용중' } : c))
  }

  return (
    <div style={s.root}>
      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{coupons.length}</b>건</span>
        <button style={s.btnPrimary} onClick={openAdd}>+ 쿠폰 발행</button>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>{['번호', '쿠폰명', '발행일', '발행수량', '유효기간', '사용건수', '사용율', '서비스상태', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {coupons.map(c => {
              const useRate = ((c.used / c.quantity) * 100).toFixed(1)
              return (
                <tr key={c.id} style={styles.tr}>
                  <td style={styles.td}>{c.id}</td>
                  <td style={styles.td}><b style={{ cursor: 'pointer', color: '#4f46e5' }} onClick={() => openDetail(c)}>{c.name}</b></td>
                  <td style={styles.td}>{c.issueDate}</td>
                  <td style={styles.td}>{c.quantity?.toLocaleString()}</td>
                  <td style={styles.td}>{c.expiry}</td>
                  <td style={styles.td}>{c.used?.toLocaleString()}</td>
                  <td style={styles.td}>
                    <div style={styles.progressBar}>
                      <div style={{ ...styles.progressFill, width: useRate + '%', background: useRate > 80 ? '#dc2626' : '#4f46e5' }} />
                    </div>
                    <span style={{ fontSize: 11, color: '#888' }}>{useRate}%</span>
                  </td>
                  <td style={styles.td}>
                    <span style={{ ...styles.badge, background: c.status === '사용중' ? '#d1fae5' : '#fee2e2', color: c.status === '사용중' ? '#059669' : '#dc2626' }}>
                      {c.status}
                    </span>
                  </td>
                  <td style={styles.td}>
                    <button style={styles.btnSm} onClick={() => openDetail(c)}>상세</button>
                    <button style={{ ...styles.btnSm, background: c.status === '사용중' ? '#fff7ed' : '#d1fae5', color: c.status === '사용중' ? '#d97706' : '#059669' }}
                      onClick={() => toggleStatus(c.id)}>
                      {c.status === '사용중' ? '중지' : '재개'}
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* 쿠폰 발행 모달 */}
      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>쿠폰 발행</div>
            <div style={s.mFields}>
              <div style={s.mf}><label style={s.ml}>쿠폰명</label>
                <input style={s.mi} value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} placeholder="쿠폰 이름" />
              </div>
              <div style={s.mf}><label style={s.ml}>헤더 문구</label>
                <input style={s.mi} value={form.header} onChange={e => setForm(p => ({ ...p, header: e.target.value }))} placeholder="예) 신규가입 특별 혜택!" />
              </div>
              <div style={{ display: 'flex', gap: 12 }}>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>종류</label>
                  <select style={s.mi} value={form.type} onChange={e => setForm(p => ({ ...p, type: e.target.value }))}>
                    {COUPON_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
                  </select>
                </div>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>{form.type === '강의기간' ? '기간(일)' : '할인 값'}</label>
                  <input style={s.mi} type="number" value={form.discountValue} onChange={e => setForm(p => ({ ...p, discountValue: e.target.value }))}
                    placeholder={form.type === '할인율' ? '예) 30 (30%)' : form.type === '정액할인' ? '예) 5000 (원)' : '예) 30 (일)'} />
                </div>
              </div>
              <div style={{ display: 'flex', gap: 12 }}>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>발행 수량</label>
                  <input style={s.mi} type="number" value={form.quantity} onChange={e => setForm(p => ({ ...p, quantity: e.target.value }))} placeholder="예) 1000" />
                </div>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>유효기간</label>
                  <input type="date" style={s.mi} value={form.expiry} onChange={e => setForm(p => ({ ...p, expiry: e.target.value }))} />
                </div>
              </div>
            </div>
            <div style={s.mbtn}>
              <button style={s.btnPrimary} onClick={save}>쿠폰 발행</button>
              <button style={s.btnOutline} onClick={() => setModal(false)}>취소</button>
            </div>
          </div>
        </div>
      )}

      {/* 쿠폰 상세 모달 */}
      {detailModal && selectedCoupon && (
        <div style={s.overlay}>
          <div style={{ ...s.modal, width: 640 }}>
            <div style={s.modalTitle}>쿠폰 상세 - {selectedCoupon.name}</div>
            <div style={s.couponInfo}>
              <div style={s.ciRow}><span style={s.ciLabel}>발행일</span><span>{selectedCoupon.issueDate}</span></div>
              <div style={s.ciRow}><span style={s.ciLabel}>유효기간</span><span>{selectedCoupon.expiry}</span></div>
              <div style={s.ciRow}><span style={s.ciLabel}>발행수량</span><span>{selectedCoupon.quantity?.toLocaleString()}개</span></div>
              <div style={s.ciRow}><span style={s.ciLabel}>사용건수</span><span>{selectedCoupon.used?.toLocaleString()}건</span></div>
            </div>
            <div style={s.tableSubTitle}>쿠폰 코드 목록 (샘플)</div>
            <div style={{ ...s.tableWrap, maxHeight: 250 }}>
              <table style={s.table}>
                <thead>
                  <tr>{['번호', '쿠폰 코드', '등록일시', '사용자 아이디'].map(h => <th key={h} style={s.th}>{h}</th>)}</tr>
                </thead>
                <tbody>
                  {sampleCodes(selectedCoupon.id).map(code => (
                    <tr key={code.id} style={styles.tr}>
                      <td style={styles.td}>{code.id}</td>
                      <td style={styles.td}><code style={{ fontSize: 12, background: '#f3f4f6', padding: '2px 6px', borderRadius: 4 }}>{code.code}</code></td>
                      <td style={styles.td}>{code.regDate}</td>
                      <td style={styles.td}><span style={{ color: code.userId !== '-' ? '#4f46e5' : '#bbb' }}>{code.userId}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div style={s.mbtn}>
              <button style={s.btnOutline} onClick={() => setDetailModal(false)}>닫기</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const s = {
  root: { display: 'flex', flexDirection: 'column', gap: 16 },
  tableHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  total: { fontSize: 13, color: '#555' },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse' },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 520, boxShadow: '0 20px 60px rgba(0,0,0,0.2)', maxHeight: '85vh', overflowY: 'auto' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 20, color: '#1a1a2e' },
  mFields: { display: 'flex', flexDirection: 'column', gap: 14 },
  mf: { display: 'flex', flexDirection: 'column', gap: 4 }, ml: { fontSize: 12, color: '#666', fontWeight: 600 },
  mi: { padding: '10px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  mbtn: { display: 'flex', gap: 10, marginTop: 24, justifyContent: 'flex-end' },
  couponInfo: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, background: '#f8f9fa', borderRadius: 10, padding: 16, marginBottom: 20 },
  ciRow: { display: 'flex', gap: 8, fontSize: 13 },
  ciLabel: { color: '#888', fontWeight: 600, minWidth: 60 },
  tableSubTitle: { fontSize: 14, fontWeight: 700, color: '#1a1a2e', marginBottom: 10 },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
}
const styles = {
  tr: { borderBottom: '1px solid #fafafa' }, td: { padding: '10px 12px', fontSize: 13, color: '#333' },
  badge: { padding: '3px 10px', borderRadius: 20, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer', marginRight: 4 },
  progressBar: { width: 80, height: 6, background: '#e5e7eb', borderRadius: 3, marginBottom: 2, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 3, transition: 'width 0.3s' },
}
