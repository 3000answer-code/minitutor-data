import { useState } from 'react'

export default function DataTable({ columns, data, onRowClick, actions, pageSize = 10 }) {
  const [page, setPage] = useState(1)
  const [sortKey, setSortKey] = useState(null)
  const [sortDir, setSortDir] = useState('asc')

  const handleSort = (key) => {
    if (sortKey === key) setSortDir(d => d === 'asc' ? 'desc' : 'asc')
    else { setSortKey(key); setSortDir('asc') }
  }

  let sorted = [...data]
  if (sortKey) {
    sorted.sort((a, b) => {
      const v1 = a[sortKey], v2 = b[sortKey]
      if (v1 < v2) return sortDir === 'asc' ? -1 : 1
      if (v1 > v2) return sortDir === 'asc' ? 1 : -1
      return 0
    })
  }

  const total = sorted.length
  const totalPages = Math.ceil(total / pageSize)
  const paged = sorted.slice((page - 1) * pageSize, page * pageSize)

  return (
    <div>
      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>
              {columns.map(col => (
                <th key={col.key} style={{ ...s.th, width: col.width }}
                  onClick={() => col.sortable !== false && handleSort(col.key)}>
                  {col.label}
                  {col.sortable !== false && (
                    <span style={s.sortIcon}>
                      {sortKey === col.key ? (sortDir === 'asc' ? ' ▲' : ' ▼') : ' ↕'}
                    </span>
                  )}
                </th>
              ))}
              {actions && <th style={s.th}>관리</th>}
            </tr>
          </thead>
          <tbody>
            {paged.length === 0 ? (
              <tr><td colSpan={columns.length + (actions ? 1 : 0)} style={s.empty}>데이터가 없습니다</td></tr>
            ) : paged.map((row, i) => (
              <tr key={row.id || i} style={s.tr} onClick={() => onRowClick && onRowClick(row)}>
                {columns.map(col => (
                  <td key={col.key} style={s.td}>
                    {col.render ? col.render(row[col.key], row) : row[col.key]}
                  </td>
                ))}
                {actions && (
                  <td style={s.td} onClick={e => e.stopPropagation()}>
                    <div style={s.actions}>{actions(row)}</div>
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div style={s.pagination}>
        <span style={s.pageInfo}>총 {total}건 | {page}/{totalPages} 페이지</span>
        <div style={s.pageBtns}>
          <button style={s.pageBtn} onClick={() => setPage(1)} disabled={page === 1}>«</button>
          <button style={s.pageBtn} onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>‹</button>
          {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
            const start = Math.max(1, page - 2)
            const p = start + i
            if (p > totalPages) return null
            return (
              <button key={p} style={{ ...s.pageBtn, ...(p === page ? s.pageBtnActive : {}) }} onClick={() => setPage(p)}>{p}</button>
            )
          })}
          <button style={s.pageBtn} onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>›</button>
          <button style={s.pageBtn} onClick={() => setPage(totalPages)} disabled={page === totalPages}>»</button>
        </div>
      </div>
    </div>
  )
}

export function Badge({ text, type = 'default' }) {
  const colors = {
    success: { bg: '#dcfce7', color: '#16a34a' },
    danger: { bg: '#fee2e2', color: '#dc2626' },
    warning: { bg: '#fef9c3', color: '#ca8a04' },
    info: { bg: '#dbeafe', color: '#2563eb' },
    default: { bg: '#f3f4f6', color: '#6b7280' },
  }
  const c = colors[type] || colors.default
  return <span style={{ ...bs.badge, background: c.bg, color: c.color }}>{text}</span>
}

const bs = {
  badge: { padding: '2px 8px', borderRadius: 20, fontSize: 11, fontWeight: 600, display: 'inline-block' }
}

const s = {
  tableWrap: { overflowX: 'auto', borderRadius: 12, border: '1px solid #e5e7eb' },
  table: { minWidth: 600, background: '#fff' },
  th: {
    padding: '12px 14px', background: '#f8fafc',
    textAlign: 'left', fontSize: 12, fontWeight: 700,
    color: '#555', borderBottom: '1px solid #e5e7eb',
    whiteSpace: 'nowrap', cursor: 'pointer', userSelect: 'none',
  },
  sortIcon: { opacity: 0.4, fontSize: 10 },
  tr: { cursor: 'pointer', transition: 'background 0.15s' },
  td: {
    padding: '11px 14px', fontSize: 13,
    borderBottom: '1px solid #f0f0f0',
    color: '#333', verticalAlign: 'middle',
  },
  empty: { padding: 40, textAlign: 'center', color: '#aaa', fontSize: 14 },
  actions: { display: 'flex', gap: 6 },
  pagination: {
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    padding: '12px 4px', marginTop: 4,
  },
  pageInfo: { fontSize: 12, color: '#888' },
  pageBtns: { display: 'flex', gap: 4 },
  pageBtn: {
    width: 32, height: 32, borderRadius: 6,
    background: '#fff', border: '1px solid #e5e7eb',
    fontSize: 13, color: '#555', cursor: 'pointer',
  },
  pageBtnActive: { background: '#4f46e5', color: '#fff', borderColor: '#4f46e5' },
}
