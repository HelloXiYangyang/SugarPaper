export default async function tracedFetch(uri: string, init?: RequestInit) {
  return fetch(uri, init);
}
