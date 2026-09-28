import { categories, type Sections } from '../../lib/notes';
export default function ReleaseNotes({sections}: {sections: Sections}) {
  return <div className="release-notes">{Object.entries(categories).map(([key,label]) => {
    const items=sections[key as keyof Sections];
    return items.length ? <section key={key} className="note-category"><h3>{label}</h3><ul>{items.map(item => <li key={item}>{item}</li>)}</ul></section> : null;
  })}</div>;
}
