const token: string = 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253QGdtYWlsLmNvbSIsImlhdCI6MTc3MjEzNTQyOCwiZXhwIjoxNzcyMjIxODI4fQ.16K_NfLGxbctAgtC3OTwHNigHieBw0RNksSycUNNv-pzOCs5oWNPVLwodLVb0yVVWSJOqMPlIjAVbec7VEvVHw'

async function createStudent() {
  const res = await fetch("http://136.116.64.6/api/admin/users", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    }
});

  const data = await res.json();
  console.log(data);
}

export default async function tst() {

    await createStudent();

    return (
        <div>
            <h1>Test Page</h1>
        </div>
    )
}