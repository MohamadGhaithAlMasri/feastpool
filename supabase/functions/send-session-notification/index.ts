import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts"

// Firebase service account details
const FIREBASE_PROJECT_ID = "feastpool-f6470"
const FIREBASE_CLIENT_EMAIL = "firebase-adminsdk-fbsvc@feastpool-f6470.iam.gserviceaccount.com"
const FIREBASE_PRIVATE_KEY = `-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDE2V09NUuaIGBm
4uCprgQnTLhH8wTJkkyhK7td25aUSO5+fHhINrtftwAcOWUGhwUs1rJQbKglIxSN
pfFpiyrg0cVhB5OtwLRwQRcQaKGbcOZTQEVqnCPElFcUYDRnUeHGfJDPIJlQNY1W
0F2lsFZG/lZP9h002qtZKktt+aJ1qixkEdgcz1WaLKKgQ+4A1/TzAT0DZAzOCitW
23Yd9i0Iig3gm4VQJWkBG0KN9X+JPLvPXQV17tFFAI55Jv3ZHwnG7srJx3T+lF79
YcJS150m8K87TubxA8CuF3FCl1Un8Q+5lbPuYX3YdRoYwXjz6CcDPWsBcGDQXZ+E
SuM27DWdAgMBAAECggEALaH3/97xejbEMkWo8BzTgKrD04YOF45PLlOdeUoU06Y+
h1riZVcuw6cAIwrZFRTKydSxfHxb1FQYCSgtWRq2Y2ytlWs0vGQ+UAF+z8J5qDeZ
ZTYygV7V2dXLhAEzVLpCHQm2ZhW4BMSNUdE2zFie/5EpQBsdNSn169MmrkVe+GiF
EFm0QzY2o1h6ADn8Ekd63vBxBpsfHftdyFXl0nVZ8NX+Vz1TMrVrWxzb5ZXohpYw
PWJiChad46HDyDfTzD+lULxMT2/Q1gu1Zn/D5wMOQYQ3UTji3Eb7lQGpc5ptBkw0
f8U5a8kqrx+oentXduNDsAnzd+mo+L0qyUHV5sLPEQKBgQDjWMowI8OnKN/816Rr
P6ZLoA4aKYJca34x7i6kakJRdA6XWX72w/8i1HLSHrA+EblEQS0wIwZ1dRwKzS8s
7rh4PPeG6jncomxJSoOc9q/uPlcJPmmK5qbyhvSGakFmICagATDAFOkA1Zl3WkqG
1oK4n49IbyVxf6RxLguq99OzFQKBgQDdqJUdmT4zlc3M2zwQIA+c1K8t0eaDTMa8
Up1l+sqkJbvniiRPHzWmJ2Wis0yIgiAtyHZCywga7wvlLU9ctr8kRBXUvaO3FKSE
gOlyIDXZlMDC0epfAwbcsemPKnd46eTtvrfJNZcl7oWr7NTjRAfGem8y18PL4W6z
pFAZ5bE6aQKBgHbtXJ9AJjpMdJeEitsbqbdH2/itnCcSiCpAaZ/Sgiyv5G4h//vA
XbfvoLzwFsvxY5Qj8CqNN/S7tValLTd5DYDAi8/EuU4EnVbdpum2ViPv8oHAZ1+k
9tJJ7KJf9SQiT3JGDSV+CsFH+4bm8bOFhU5lEYQXuGOeHPyj1LC0AcddAoGAD0Ks
AX2raqHFqXTuja2nZYS/CsiItkFy7URC0eKSUPrIFQjNtyTO7MGJncn6Wuuai4xh
l/eidzg9+WlFLXzna/fECQGFY/Vn3jeB2vmcu34iR0dse14Z+tfE3LZvw0NXH4ch
4Bhwb4wcZ9nGTl9AqcmEHlv8fuzmUjfdy+qkaQECgYBgtDlqghLRDlrtQY6qufQP
x/30slgxE6Rv8O9N+LKjFrMehsS+GUmP0sSbXY/9tPp4G5zn6po1/AAaQ5WFLdpp
/cr7pbrXJ3jFYi1sSJs52ZuIOloYB2pUQjWRPt0LXVboJSobCgdzIZ8io05KsOF+
Q4vp17q1HfdgHiljpPQ7Hw==
-----END PRIVATE KEY-----`

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Read request body to determine if this is a startup or arrival notification
    const reqBody = await req.json().catch(() => ({}));
    const status = reqBody.status || 'STARTED';
    const category = reqBody.category;

    let notificationTitle = "FeastPool Started! 🍔";
    let notificationBody = category && category !== 'All'
      ? `Order window is open for 15 minutes. Category: ${category}. Add your meals now!`
      : "Order window is open for 15 minutes. Add your meals now!";

    if (status === 'ARRIVED') {
      notificationTitle = "Food Arrived! 🍕";
      notificationBody = "The lunch pool order has arrived. Enjoy your meal!";
    }

    // 2. Fetch registered device tokens
    const { data: tokensData, error: tokensError } = await supabaseClient
      .from('device_tokens')
      .select('token')

    if (tokensError) throw tokensError

    const tokens = tokensData.map((d: any) => d.token)
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No registered tokens found" }), { status: 200 })
    }

    // 3. Fetch Google OAuth Access Token
    const accessToken = await getGoogleAccessToken(FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY)

    // 4. Send Notification to each token via Firebase API v1
    const promises = tokens.map(token => {
      return fetch(`https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: {
            token: token,
            notification: {
              title: notificationTitle,
              body: notificationBody
            }
          }
        })
      })
    })

    const responses = await Promise.all(promises)
    const results = await Promise.all(responses.map(r => r.json()))

    return new Response(JSON.stringify({ success: true, sentTo: tokens.length, results }), { status: 200 })
  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 })
  }
})

async function getGoogleAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: getNumericDate(3600),
      iat: getNumericDate(0),
    },
    await crypto.subtle.importKey(
      "pkcs8",
      pemToPkcs8(privateKey),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    )
  )

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  })

  const data = await res.json()
  if (!data.access_token) {
    throw new Error(`Failed to retrieve OAuth token: ${JSON.stringify(data)}`)
  }
  return data.access_token
}

function pemToPkcs8(pem: string): Uint8Array {
  const pemHeader = "-----BEGIN PRIVATE KEY-----"
  const pemFooter = "-----END PRIVATE KEY-----"
  const pemContents = pem
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "")
  const binaryDerString = atob(pemContents)
  const binaryDer = new Uint8Array(binaryDerString.length)
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i)
  }
  return binaryDer
}
