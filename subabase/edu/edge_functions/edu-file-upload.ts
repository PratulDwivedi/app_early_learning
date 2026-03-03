// supabase/functions/edu-file-upload/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 })
    }

    const formData = await req.formData()
    const file = formData.get("file") as File

    if (!file) {
      return new Response(
        JSON.stringify({ error: "File not provided" }),
        { status: 400 }
      )
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const fileExt = file.name.split(".").pop()
    const fileName = `${crypto.randomUUID()}.${fileExt}`

    const { data, error } = await supabase.storage
      .from("edu_files")
      .upload(fileName, file, {
        contentType: file.type,
      })

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500 }
      )
    }

    const { data: publicUrl } = supabase.storage
      .from("edu_files")
      .getPublicUrl(fileName)

    return new Response(
      JSON.stringify({
        message: "File uploaded successfully",
        file_name: fileName,
        public_url: publicUrl.publicUrl,
      }),
      { status: 200 }
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500 }
    )
  }
})