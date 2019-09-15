//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.4.17;
import './Pairing.sol';

contract Verifier is Pairing {
//    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() pure internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([18939567037258844031220219027528000781807445166415628431411816431391472046879,17720659371943185502240683113490814991769808842604761520772560033593385245111], [1250780378425302916468843162321101235495506855388241326257418302491254772807,16224613695535965272214956753970249105529567674760610976486292996690785166590]);
        vk.B = Pairing.G1Point(14250031111948761209799027459658732031397437651137223562869769681035040408696,20769240540830736544321201656477777107326502104884462896758556083368492822610);
        vk.C = Pairing.G2Point([6154886985200468418618825368679284517700928891984089263042810710173790924670,927796733094937319434252910610095344808866177014577552542648596484794855547], [10345631301060038451755060480746298327701936724289674420310680258801827787375,13889245472765795529460838165950370760377231155435614163957124341984894499734]);
        vk.gamma = Pairing.G2Point([6064299908400588606605572738566833733648030141808633328190144998512078753122,4112950031642350236399047257681456355633563232242454619994549530390978532838], [4159940182818652875070958950888297481904683080761434483076061122562081128591,16748880756021166768900406190823982438499928468840057028849504802366934761717]);
        vk.gammaBeta1 = Pairing.G1Point(5275741521856001507398268489002017126299566266048215501296783578042059665289,908054022158697387635388391303252157597679726155747090564000014023096462765);
        vk.gammaBeta2 = Pairing.G2Point([10562751009993987213995248379967512128617127403958196588902720937298808927806,979614369246031463052010544935995485119396624541678950013325261198128068789], [228862072315251431832803655597144273644541054644404512865449176689522255267,1004067040304357694574807596532394697365226900305545894116677217744729981455]);
        vk.Z = Pairing.G2Point([14619087371227976522611399095121490933475616750268686515245593692310827637304,7581474580865630393882375345215397582773520458078591460697048235379839513250], [4398238753999975039582553400004249240945291588013719252114221625265584533111,15364116581239958849781678337711011790983845918579485281809779183045149406315]);
        vk.IC = new Pairing.G1Point[](2);
        vk.IC[0] = Pairing.G1Point(8907330670933996273628840815525941644681884278544535381877850280259570512123,6070900417910494540149707715008562233471048543349870174130188505568254681272);
        vk.IC[1] = Pairing.G1Point(15723519100598759961249864591342112589565720861018094077798684048077625740857,19811890610852771205621309826217952599423485729299022663868560309981110459288);

    }
    function verify(uint[] input, Proof proof) view internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    function verifyProof(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[1] input
        ) view public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}




