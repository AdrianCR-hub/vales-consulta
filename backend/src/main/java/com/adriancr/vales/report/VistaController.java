package com.adriancr.vales.report;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class VistaController {
    @GetMapping("/")
    public String inicio() {
        return "redirect:/app/index.html";
    }
}
