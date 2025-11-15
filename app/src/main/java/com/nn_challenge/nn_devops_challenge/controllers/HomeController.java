package com.nn_challenge.nn_devops_challenge;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping({"/", "/index"})
    public String home() {
        return "forward:/index.html";
    }
}